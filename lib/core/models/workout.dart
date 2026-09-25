// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'json_passthrough.dart';
import 'set_entry.dart';

/// One exercise's sets within a workout (`../openGym/api/openapi.yaml` Workout schema `entries`;
/// `sg` from `../openGym/frontend/src/lib/history.js` `supersetUnits` -- consecutive entries
/// sharing `sg` are a superset).
class WorkoutEntry extends Equatable {
  const WorkoutEntry({
    this.id,
    this.sets,
    this.topW,
    this.sg,
    this.rid,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final List<SetEntry>? sets;
  final num? topW;
  final String? sg;
  final String? rid;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'sets', 'topW', 'sg', 'rid'};

  factory WorkoutEntry.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return WorkoutEntry(
      id: reader.string('id'),
      sets: reader.objectList<SetEntry>('sets', SetEntry.fromJson),
      topW: reader.number('topW'),
      sg: reader.string('sg'),
      rid: reader.string('rid'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'sets': sets?.map((SetEntry s) => s.toJson()).toList(),
        'topW': topW,
        'sg': sg,
        'rid': rid,
      });

  @override
  List<Object?> get props => <Object?>[id, sets, topW, sg, rid, extra];
}

/// A completed workout (`../openGym/frontend/src/lib/demoSeed.js` ~line 125,
/// `../openGym/api/openapi.yaml` Workout schema) or the in-progress `active` workout
/// (`../openGym/frontend/src/sheets.jsx` ~line 1814 -- same shape, plus active-only keys such
/// as `routineIds`, `cur`, `view`, `backfill`, which fall through to [extra] on a completed
/// workout and are read directly here since `active` is also modeled as a [Workout]).
///
/// Passthrough-safe: every unknown key, explicit null and wrong-typed value on a known field
/// survives `fromJson` -> `toJson` unchanged, at every nesting level (entries, sets, drops,
/// clusters, sides).
class Workout extends Equatable {
  const Workout({
    this.id,
    this.d,
    this.start,
    this.end,
    this.routineId,
    this.routineIds,
    this.name,
    this.bw,
    this.vol,
    this.prs,
    this.entries,
    this.cur,
    this.view,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final String? d;
  final num? start;
  final num? end;
  final String? routineId;
  final List<String>? routineIds;
  final String? name;
  final num? bw;
  final num? vol;
  final List<String>? prs;
  final List<WorkoutEntry>? entries;
  final int? cur;
  final String? view;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'id', 'd', 'start', 'end', 'routineId', 'routineIds', 'name', 'bw', 'vol', 'prs', 'entries',
    'cur', 'view',
  };

  factory Workout.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return Workout(
      id: reader.string('id'),
      d: reader.string('d'),
      start: reader.number('start'),
      end: reader.number('end'),
      routineId: reader.string('routineId'),
      routineIds: reader.stringList('routineIds'),
      name: reader.string('name'),
      bw: reader.number('bw'),
      vol: reader.number('vol'),
      prs: reader.stringList('prs'),
      entries: reader.objectList<WorkoutEntry>('entries', WorkoutEntry.fromJson),
      cur: reader.integer('cur'),
      view: reader.string('view'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'd': d,
        'start': start,
        'end': end,
        'routineId': routineId,
        'routineIds': routineIds,
        'name': name,
        'bw': bw,
        'vol': vol,
        'prs': prs,
        'entries': entries?.map((WorkoutEntry e) => e.toJson()).toList(),
        'cur': cur,
        'view': view,
      });

  /// Returns a copy with the given fields replaced. Every field parameter defaults to a private
  /// sentinel, so passing `null` explicitly *clears* the field (openGym writes explicit nulls,
  /// e.g. `active = null` when a workout ends): the typed value becomes null and `extra` gets
  /// `key: null`, so [toJson] emits an explicit null. Passing a non-null value sets the typed
  /// field and drops any stale entry for that key from `extra` (left over from a null or
  /// wrong-typed value demoted by `JsonReader`). Omitted fields are kept as they are.
  /// [extra], if given, replaces the base `extra` map before those per-key adjustments.
  Workout copyWith({
    Object? id = _unset,
    Object? d = _unset,
    Object? start = _unset,
    Object? end = _unset,
    Object? routineId = _unset,
    Object? routineIds = _unset,
    Object? name = _unset,
    Object? bw = _unset,
    Object? vol = _unset,
    Object? prs = _unset,
    Object? entries = _unset,
    Object? cur = _unset,
    Object? view = _unset,
    Map<String, Object?>? extra,
  }) {
    final Map<String, Object?> nextExtra = <String, Object?>{...(extra ?? this.extra)};
    T? pick<T>(Object? value, T? current, String key) {
      if (identical(value, _unset)) return current;
      if (value == null) {
        nextExtra[key] = null;
        return null;
      }
      nextExtra.remove(key);
      return value as T;
    }

    return Workout(
      id: pick<String>(id, this.id, 'id'),
      d: pick<String>(d, this.d, 'd'),
      start: pick<num>(start, this.start, 'start'),
      end: pick<num>(end, this.end, 'end'),
      routineId: pick<String>(routineId, this.routineId, 'routineId'),
      routineIds: pick<List<String>>(routineIds, this.routineIds, 'routineIds'),
      name: pick<String>(name, this.name, 'name'),
      bw: pick<num>(bw, this.bw, 'bw'),
      vol: pick<num>(vol, this.vol, 'vol'),
      prs: pick<List<String>>(prs, this.prs, 'prs'),
      entries: pick<List<WorkoutEntry>>(entries, this.entries, 'entries'),
      cur: pick<int>(cur, this.cur, 'cur'),
      view: pick<String>(view, this.view, 'view'),
      extra: Map<String, Object?>.unmodifiable(nextExtra),
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => <Object?>[
        id,
        d,
        start,
        end,
        routineId,
        routineIds,
        name,
        bw,
        vol,
        prs,
        entries,
        cur,
        view,
        extra,
      ];
}
