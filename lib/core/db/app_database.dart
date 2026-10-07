// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Opens and owns the app's local sqflite database through an injectable [DatabaseFactory], so
/// production code (the real platform plugin, via [defaultPath]) and any throwaway verification
/// script (`databaseFactoryFfi` against an in-memory path) share the exact same schema and
/// opening logic.
class AppDatabase {
  AppDatabase._(this.db);

  /// The underlying sqflite [Database]. Exposed so [GymStateRepository]
  /// (`lib/core/data/gym_state_repository.dart`) can run queries/transactions directly.
  final Database db;

  /// Opens (creating on first run) the database at [path] using [factory], running every
  /// [kCreateStatementsV1] statement in a single batch on create. No platform code runs unless
  /// [factory] itself is platform-backed -- callers pass `databaseFactoryFfi` for headless
  /// verification and the real plugin factory (via [defaultPath]) in the app.
  static Future<AppDatabase> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final Database database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onCreate: (Database db, int version) async {
          final Batch batch = db.batch();
          for (final String statement in kCreateStatementsV2) {
            batch.execute(statement);
          }
          await batch.commit(noResult: true);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute(kCreateBackupSettingsTable);
          }
        },
      ),
    );
    return AppDatabase._(database);
  }

  /// The app's default on-device database path: the platform databases directory (Android:
  /// app-private `databases/`; iOS/macOS: Documents) joined with `open_exercise.db`. Relies on
  /// the real sqflite plugin factory being registered (i.e. running on-device, not in a plain
  /// Dart VM), so it is never called from a headless verification script.
  static Future<String> defaultPath() async {
    final String dir = await getDatabasesPath();
    return p.join(dir, 'open_exercise.db');
  }

  Future<void> close() => db.close();
}
