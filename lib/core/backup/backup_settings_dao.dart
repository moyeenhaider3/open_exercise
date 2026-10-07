// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../db/schema.dart';
import 'backup_settings.dart';

class BackupSettingsDao {
  const BackupSettingsDao(this._database);

  final AppDatabase _database;

  Future<BackupSettings> load() async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.backupSettings,
      where: 'id = ?',
      whereArgs: const <int>[1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const BackupSettings();
    }
    return BackupSettings.fromRow(rows.first);
  }

  Future<void> save(BackupSettings settings) async {
    await _database.db.insert(
      Tables.backupSettings,
      settings.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLastBackupAt(DateTime time) async {
    await _database.db.update(
      Tables.backupSettings,
      <String, Object?>{
        Tables.colLastBackupAt: time.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: const <int>[1],
    );
  }

  Future<void> clear() async {
    await _database.db.delete(
      Tables.backupSettings,
      where: 'id = ?',
      whereArgs: const <int>[1],
    );
  }
}
