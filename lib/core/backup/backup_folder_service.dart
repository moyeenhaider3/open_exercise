// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'backup_bookmark_channel.dart';
import 'backup_settings.dart';
import 'backup_settings_dao.dart';

final class BackupFolderService {
  BackupFolderService({
    required this.settingsDao,
    required this.bookmarkChannel,
  });

  final BackupSettingsDao settingsDao;
  final BackupBookmarkChannel bookmarkChannel;

  /// Opens the system folder picker.
  /// Android: SAF tree picker -> persisted URI/path.
  /// iOS: folder doc picker -> security-scoped bookmark via BackupBookmarkChannel.
  /// Returns the display folder name, or null if cancelled.
  Future<String?> pickFolder() async {
    final String? selectedDirectory =
        await FilePickerPlatform.instance.getDirectoryPath();
    if (selectedDirectory == null) {
      return null;
    }

    final String folderName = p.basename(selectedDirectory);
    final String displayName =
        folderName.trim().isEmpty ? 'Backups' : folderName.trim();

    if (Platform.isIOS) {
      try {
        final String bookmark =
            await bookmarkChannel.createBookmark(selectedDirectory);
        final BackupSettings current = await settingsDao.load();
        await settingsDao.save(current.copyWith(
          folderBookmark: bookmark,
          folderName: displayName,
          folderUri: selectedDirectory,
          autoBackupEnabled: true,
        ));
        return displayName;
      } catch (_) {
        return null;
      }
    } else {
      final BackupSettings current = await settingsDao.load();
      await settingsDao.save(current.copyWith(
        folderUri: selectedDirectory,
        folderName: displayName,
        autoBackupEnabled: true,
      ));
      return displayName;
    }
  }

  /// Writes [content] as [fileName] into the previously chosen folder.
  /// Android: write to folder path.
  /// iOS: resolve bookmark, write, stop accessing.
  /// Returns true on success.
  Future<bool> writeFile(String fileName, String content) async {
    final BackupSettings settings = await settingsDao.load();
    if (!settings.hasFolderConfigured) {
      return false;
    }

    if (Platform.isIOS && settings.folderBookmark != null) {
      final ResolveBookmarkResult res =
          await bookmarkChannel.resolveBookmark(settings.folderBookmark!);
      if (!res.isSuccess || res.path == null) {
        return false;
      }
      try {
        final String targetPath = p.join(res.path!, fileName);
        final File file = File(targetPath);
        await file.writeAsString(content, flush: true);
        return true;
      } catch (_) {
        return false;
      } finally {
        await bookmarkChannel.stopAccessing();
      }
    } else if (settings.folderUri != null) {
      try {
        final String targetPath = p.join(settings.folderUri!, fileName);
        final File file = File(targetPath);
        await file.writeAsString(content, flush: true);
        return true;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  /// Checks if the configured folder is still accessible.
  /// Returns false if permission revoked, folder deleted, or bookmark stale.
  Future<bool> isFolderAccessible() async {
    final BackupSettings settings = await settingsDao.load();
    if (!settings.hasFolderConfigured) {
      return false;
    }

    if (Platform.isIOS && settings.folderBookmark != null) {
      final ResolveBookmarkResult res =
          await bookmarkChannel.resolveBookmark(settings.folderBookmark!);
      if (!res.isSuccess || res.path == null) {
        return false;
      }
      try {
        return await Directory(res.path!).exists();
      } catch (_) {
        return false;
      } finally {
        await bookmarkChannel.stopAccessing();
      }
    } else if (settings.folderUri != null) {
      try {
        return await Directory(settings.folderUri!).exists();
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> clearFolder() async {
    final BackupSettings current = await settingsDao.load();
    await settingsDao.save(current.copyWith(
      clearFolderUri: true,
      clearFolderBookmark: true,
      clearFolderName: true,
    ));
  }
}
