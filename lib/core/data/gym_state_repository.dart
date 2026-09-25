// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:sqflite/sqflite.dart' show Batch, Database, Transaction;

import '../db/app_database.dart';
import '../db/schema.dart';
import '../models/gym_state.dart';

/// The single local (never-synced) profile before any server account exists or is signed into
/// (`../openGym/frontend/src/store/useStore.js` guest-mode storage key). A signed-in profile is
/// keyed by its own server-assigned user id instead.
const String kLocalGuestUid = 'local';

/// Persists the whole openGym profile document (`GymState.toJson()`/`GymState.fromJson`) to
/// sqflite, one row set per `uid`, via the hybrid schema in `lib/core/db/schema.dart`.
///
/// `importState`/`exportState` operate on the raw decoded document -- no `kDefaultState` overlay,
/// no key stripping, no `_rev` stamping -- so `importState(uid, doc)` then `exportState(uid)`
/// returns a document deep-equal to `doc`, whatever `doc` contains (including keys this model
/// doesn't know about, wrongly-typed values, and explicit nulls). Deep-equal only, not
/// byte-for-byte: `workouts`/`routines`/`bodyweight` come back at the end of the key order, and
/// re-encoding may format numbers differently from JavaScript (`60.0` vs `60`). The
/// `kDefaultState` overlay only happens when a typed [GymState] is built, in [loadState].
///
/// Every statement here uses `db.insert`/`db.query`/`db.delete`/`db.batch` with bound `whereArgs`
/// -- never `rawQuery`/`rawInsert`/`rawUpdate`/`rawDelete`/`execute` with an interpolated value --
/// so a `uid` or document value containing SQL metacharacters is always treated as inert data,
/// never as SQL syntax (Research Security Domain V5; STRIDE T-1-01).
class GymStateRepository {
  // Keeps the public `database:` param name independent of the private field name.
  // ignore: prefer_initializing_formals
  GymStateRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Database get _db => _database.db;

  /// Replaces every row for [uid] with the contents of [doc] inside a single transaction, so a
  /// mid-write failure never leaves a partially-imported profile (STRIDE T-1-10): the delete and
  /// every insert either all land or none do.
  ///
  /// `workouts`/`routines`/`bodyweight` are split into their own tables (one row per element,
  /// `pos` = list index, ordered chronologically); every other top-level key (including `_ts`,
  /// `_rev`, `active`, and any key this model doesn't know about) stays as one opaque
  /// `user_state.doc_json` document. `active` is never stripped and `_rev` is never restamped
  /// here -- that is server-side PUT /api/data behaviour (`../openGym/api/server.js`
  /// `PUT /api/data`), not local import/export (Research Pitfall 5).
  Future<void> importState(String uid, Map<String, Object?> doc) async {
    await _db.transaction((Transaction txn) => _importInTxn(txn, uid, doc));
  }

  /// [importState]'s body, run inside the caller's [txn].
  Future<void> _importInTxn(Transaction txn, String uid, Map<String, Object?> doc) async {
    await txn.delete(Tables.userState, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
    await txn.delete(Tables.workouts, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
    await txn.delete(Tables.routines, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
    await txn.delete(Tables.bodyweight, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);

    final Map<String, Object?> rest = Map<String, Object?>.of(doc);
    final Batch batch = txn.batch();

    final int? workoutsPresent = _splitArrayKey(
      batch: batch,
      rest: rest,
      doc: doc,
      uid: uid,
      key: 'workouts',
      table: Tables.workouts,
      indexColumns: _workoutIndexColumns,
    );
    final int? routinesPresent = _splitArrayKey(
      batch: batch,
      rest: rest,
      doc: doc,
      uid: uid,
      key: 'routines',
      table: Tables.routines,
      indexColumns: _routineIndexColumns,
    );
    final int? bodyweightPresent = _splitArrayKey(
      batch: batch,
      rest: rest,
      doc: doc,
      uid: uid,
      key: 'bodyweight',
      table: Tables.bodyweight,
      indexColumns: _bodyweightIndexColumns,
    );

    final Object? tsRaw = doc['_ts'];
    final Object? revRaw = doc['_rev'];

    batch.insert(Tables.userState, <String, Object?>{
      Tables.colUid: uid,
      Tables.colDocJson: jsonEncode(rest),
      Tables.colTs: tsRaw is num ? tsRaw : null,
      Tables.colRev: revRaw is int ? revRaw : null,
      Tables.colWorkoutsPresent: workoutsPresent,
      Tables.colRoutinesPresent: routinesPresent,
      Tables.colBodyweightPresent: bodyweightPresent,
      Tables.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    });

    await batch.commit(noResult: true);
  }

  /// Sets only the top-level `theme` and/or `accent` keys of [uid]'s profile (a `null` argument
  /// leaves that key alone), and returns the updated `user_state.doc_json` document (it does not
  /// contain split-out `workouts`/`routines`/`bodyweight`).
  ///
  /// Read and write happen in one transaction, and only the `user_state` row is updated -- the
  /// array tables are never touched -- so a settings change can neither lose a concurrent write
  /// to the rest of the profile nor wipe it (CR-01/CR-03). If [uid] has no stored state yet, a
  /// fresh [GymState.defaults] document with the change applied is imported (openGym's DEF). If
  /// the stored `doc_json` cannot be decoded as an object this throws and writes nothing.
  ///
  /// This is a user-initiated local change, so like openGym's `persist(S, push, stamp = true)`
  /// (`useStore.js`) it stamps `_ts` with the current time: `_ts` decides which copy wins on the
  /// next pull (`restoredStateFor`). [importState] deliberately does not stamp (import/export
  /// and adopted server copies keep their own `_ts`).
  Future<Map<String, Object?>> patchSettings(String uid, {String? theme, String? accent}) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    return _db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        Tables.userState,
        columns: <String>[Tables.colDocJson],
        where: '${Tables.colUid} = ?',
        whereArgs: <Object?>[uid],
      );
      if (rows.isEmpty) {
        GymState fresh = GymState.defaults().copyWith(ts: now);
        // copyWith treats an explicit null as "clear", so only pass what is being changed.
        if (theme != null) fresh = fresh.copyWith(theme: theme);
        if (accent != null) fresh = fresh.copyWith(accent: accent);
        final Map<String, Object?> doc = fresh.toJson();
        await _importInTxn(txn, uid, doc);
        return doc;
      }
      final Object? decoded = jsonDecode(rows.first[Tables.colDocJson]! as String);
      if (decoded is! Map<String, Object?>) {
        throw FormatException('user_state.doc_json for this uid is not a JSON object');
      }
      final Map<String, Object?> doc = Map<String, Object?>.of(decoded);
      if (theme != null) doc['theme'] = theme;
      if (accent != null) doc['accent'] = accent;
      doc['_ts'] = now;
      await txn.update(
        Tables.userState,
        <String, Object?>{
          Tables.colDocJson: jsonEncode(doc),
          Tables.colTs: now,
          Tables.colUpdatedAt: now,
        },
        where: '${Tables.colUid} = ?',
        whereArgs: <Object?>[uid],
      );
      return doc;
    });
  }

  /// Reads back the document previously passed to [importState] for [uid], or `null` if [uid]
  /// has no stored state. Never adds, strips or restamps a key: `workouts`/`routines`/
  /// `bodyweight` are rebuilt (in `pos` order) only when they were stored as array rows; a
  /// present-but-not-a-list value (or an absent key) was never touched, so it survives unchanged
  /// inside `doc_json`.
  ///
  /// All reads run inside one transaction, so a concurrent [importState] for the same [uid] can
  /// never produce a torn document mixing old `doc_json`/presence flags with new array rows.
  Future<Map<String, Object?>?> exportState(String uid) {
    return _db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        Tables.userState,
        where: '${Tables.colUid} = ?',
        whereArgs: <Object?>[uid],
      );
      if (rows.isEmpty) return null;
      final Map<String, Object?> row = rows.first;
      final Map<String, Object?> doc = Map<String, Object?>.from(
        jsonDecode(row[Tables.colDocJson]! as String) as Map<String, Object?>,
      );

      if (row[Tables.colWorkoutsPresent] == 1) {
        doc['workouts'] = await _rebuildList(txn, Tables.workouts, uid);
      }
      if (row[Tables.colRoutinesPresent] == 1) {
        doc['routines'] = await _rebuildList(txn, Tables.routines, uid);
      }
      if (row[Tables.colBodyweightPresent] == 1) {
        doc['bodyweight'] = await _rebuildList(txn, Tables.bodyweight, uid);
      }
      return doc;
    });
  }

  /// [exportState] plus the `kDefaultState` overlay ([GymState.fromJson]), or `null` if [uid] has
  /// no stored state.
  Future<GymState?> loadState(String uid) async {
    final Map<String, Object?>? doc = await exportState(uid);
    if (doc == null) return null;
    return GymState.fromJson(doc);
  }

  /// [importState] with [state]'s own document ([GymState.toJson]).
  Future<void> saveState(String uid, GymState state) => importState(uid, state.toJson());

  /// Removes every row for [uid] from all four tables, inside one transaction.
  Future<void> deleteState(String uid) async {
    await _db.transaction((Transaction txn) async {
      await txn.delete(Tables.userState, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
      await txn.delete(Tables.workouts, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
      await txn.delete(Tables.routines, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
      await txn.delete(Tables.bodyweight, where: '${Tables.colUid} = ?', whereArgs: <Object?>[uid]);
    });
  }

  Future<List<Object?>> _rebuildList(Transaction txn, String table, String uid) async {
    final List<Map<String, Object?>> rows = await txn.query(
      table,
      where: '${Tables.colUid} = ?',
      whereArgs: <Object?>[uid],
      orderBy: '${Tables.colPos} ASC',
    );
    return rows.map((Map<String, Object?> r) => jsonDecode(r[Tables.colRawJson]! as String)).toList();
  }

  /// Splits [doc]'s [key] (if present) out of [rest] and into rows queued on [batch] for [table],
  /// one row per element (`pos` = index) with [indexColumns] extracting typed columns from each
  /// element via `is` checks -- a non-matching type becomes a `NULL` column while `raw_json`
  /// keeps the exact original element (STRIDE T-1-02).
  ///
  /// Returns the tri-state presence marker stored in `user_state`: `null` if [key] is absent from
  /// [doc] at all; `1` if present and a `List` (rows were queued, [rest] no longer carries it);
  /// `0` if present but not a `List` (left untouched inside [rest]/`doc_json`, no rows queued).
  /// This is what lets [exportState] tell absent vs `[]` vs a malformed value apart.
  int? _splitArrayKey({
    required Batch batch,
    required Map<String, Object?> rest,
    required Map<String, Object?> doc,
    required String uid,
    required String key,
    required String table,
    required Map<String, Object? Function(Map<String, Object?>)> indexColumns,
  }) {
    if (!doc.containsKey(key)) return null;
    final Object? value = doc[key];
    if (value is! List) return 0;

    rest.remove(key);
    for (int i = 0; i < value.length; i++) {
      final Object? element = value[i];
      final Map<String, Object?> m = element is Map<String, Object?> ? element : const <String, Object?>{};
      final Map<String, Object?> row = <String, Object?>{
        Tables.colUid: uid,
        Tables.colPos: i,
        Tables.colRawJson: jsonEncode(element),
      };
      for (final MapEntry<String, Object? Function(Map<String, Object?>)> entry in indexColumns.entries) {
        row[entry.key] = entry.value(m);
      }
      batch.insert(table, row);
    }
    return 1;
  }

  static Object? _string(Map<String, Object?> m, String key) => m[key] is String ? m[key] : null;
  static Object? _number(Map<String, Object?> m, String key) => m[key] is num ? m[key] : null;

  static final Map<String, Object? Function(Map<String, Object?>)> _workoutIndexColumns =
      <String, Object? Function(Map<String, Object?>)>{
    Tables.colId: (Map<String, Object?> m) => _string(m, 'id'),
    Tables.colD: (Map<String, Object?> m) => _string(m, 'd'),
    Tables.colStart: (Map<String, Object?> m) => _number(m, 'start'),
    Tables.colEndMs: (Map<String, Object?> m) => _number(m, 'end'),
    Tables.colRoutineId: (Map<String, Object?> m) => _string(m, 'routineId'),
  };

  static final Map<String, Object? Function(Map<String, Object?>)> _routineIndexColumns =
      <String, Object? Function(Map<String, Object?>)>{
    Tables.colId: (Map<String, Object?> m) => _string(m, 'id'),
    Tables.colName: (Map<String, Object?> m) => _string(m, 'name'),
  };

  static final Map<String, Object? Function(Map<String, Object?>)> _bodyweightIndexColumns =
      <String, Object? Function(Map<String, Object?>)>{
    Tables.colD: (Map<String, Object?> m) => _string(m, 'd'),
    Tables.colW: (Map<String, Object?> m) => _number(m, 'w'),
    Tables.colT: (Map<String, Object?> m) => _number(m, 't'),
  };
}
