// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/gym_state_repository.dart';
import 'backup_folder_service.dart';
import 'backup_result.dart';
import 'backup_settings.dart';
import 'backup_settings_dao.dart';

export 'backup_result.dart';

final class BackupRepository {
  BackupRepository({
    required this.gymStateRepository,
    required this.folderService,
    required this.settingsDao,
    required this.uid,
  });

  final GymStateRepository gymStateRepository;
  final BackupFolderService folderService;
  final BackupSettingsDao settingsDao;
  final String uid;

  String _todayIso() {
    final DateTime now = DateTime.now();
    final String y = now.year.toString().padLeft(4, '0');
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Write today's backup to the chosen folder.
  /// Overwrites same-day files (D-07).
  Future<BackupResult> backupNow() async {
    final BackupSettings settings = await settingsDao.load();
    if (!settings.hasFolderConfigured) {
      return const BackupFailure('No backup folder configured');
    }
    final bool accessible = await folderService.isFolderAccessible();
    if (!accessible) {
      return const BackupFailure('Backup folder unavailable');
    }

    try {
      final Map<String, Object?>? doc =
          await gymStateRepository.exportState(uid);
      if (doc == null) {
        return const BackupFailure('Profile data not found');
      }
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String jsonStr = encoder.convert(doc);

      final String fileName = 'opengym-backup-${_todayIso()}.json';
      final bool written = await folderService.writeFile(fileName, jsonStr);
      if (!written) {
        return const BackupFailure('Failed to write backup file');
      }

      await settingsDao.updateLastBackupAt(DateTime.now());
      return const BackupSuccess();
    } catch (e) {
      return BackupFailure(e.toString());
    }
  }

  /// Export to share sheet (D-11): write to cache dir, open share_plus.
  Future<BackupResult> exportToShareSheet(Rect? shareOrigin) async {
    try {
      final Map<String, Object?>? doc =
          await gymStateRepository.exportState(uid);
      if (doc == null) {
        return const BackupFailure('Profile data not found');
      }
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String jsonStr = encoder.convert(doc);

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'opengym-backup-${_todayIso()}.json';
      final File tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsString(jsonStr, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(tempFile.path)],
          sharePositionOrigin: shareOrigin,
        ),
      );

      return const BackupSuccess();
    } catch (e) {
      return BackupFailure(e.toString());
    }
  }

  /// Whether a backup folder is configured.
  Future<bool> isFolderConfigured() async {
    final BackupSettings settings = await settingsDao.load();
    return settings.hasFolderConfigured;
  }

  /// Pick a new backup folder. Returns the folder display name, or null.
  Future<String?> pickFolder() => folderService.pickFolder();

  /// Current backup settings (folder name, last backup time, auto enabled).
  Future<BackupSettings> getSettings() => settingsDao.load();

  /// Toggle auto-backup.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final BackupSettings current = await settingsDao.load();
    await settingsDao.save(current.copyWith(autoBackupEnabled: enabled));
  }

  /// Clear folder configuration.
  Future<void> clearFolder() => folderService.clearFolder();
}
