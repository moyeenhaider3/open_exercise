// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/default_state.dart';
import '../models/gym_state.dart';

sealed class ImportResult {
  const ImportResult();
}

final class ImportSuccess extends ImportResult {
  const ImportSuccess(this.state, this.fileName);
  final GymState state;
  final String? fileName;
}

final class ImportFailure extends ImportResult {
  const ImportFailure(this.reason);
  final String reason;
}

final class PickedBackupFile {
  const PickedBackupFile({
    required this.content,
    this.fileName,
  });

  final String content;
  final String? fileName;
}

final class BackupImportService {
  const BackupImportService();

  /// Opens the system file picker for .json files.
  /// Returns the raw file content as a String, or null if cancelled.
  Future<String?> pickBackupFile() async {
    final PickedBackupFile? picked = await pickBackupFileWithDetails();
    return picked?.content;
  }

  /// Opens the system file picker and returns content + file name if available.
  Future<PickedBackupFile?> pickBackupFileWithDetails() async {
    final List<PlatformFile> files =
        await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (files.isEmpty) {
      return null;
    }
    final PlatformFile file = files.first;
    final String? path = file.path;
    if (path == null) {
      return null;
    }
    final String content = await File(path).readAsString();
    return PickedBackupFile(content: content, fileName: file.name);
  }

  /// Validates and prepares a GymState from raw backup JSON.
  /// Matches openGym doImport: validates workouts + routines keys,
  /// overlays on kDefaultState, and parses GymState.
  ImportResult validateAndPrepare(String jsonContent, [String? fileName]) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } catch (_) {
      return const ImportFailure('Import failed: invalid JSON');
    }

    if (decoded is! Map<String, dynamic> && decoded is! Map<String, Object?>) {
      return const ImportFailure('Import failed: not an openGym backup');
    }

    final Map<String, Object?> map = (decoded as Map).cast<String, Object?>();
    if (!map.containsKey('workouts') || !map.containsKey('routines')) {
      return const ImportFailure('Import failed: not an openGym backup');
    }

    try {
      final Map<String, Object?> overlaid =
          Map<String, Object?>.from(kDefaultState)..addAll(map);
      final GymState state = GymState.fromJson(overlaid);
      return ImportSuccess(state, fileName);
    } catch (e) {
      return ImportFailure('Import failed: ${e.toString()}');
    }
  }
}
