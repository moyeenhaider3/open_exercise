// SPDX-License-Identifier: AGPL-3.0-or-later

final class BackupSettings {
  const BackupSettings({
    this.folderUri,
    this.folderBookmark,
    this.folderName,
    this.lastBackupAt,
    this.autoBackupEnabled = true,
  });

  final String? folderUri;
  final String? folderBookmark;
  final String? folderName;
  final DateTime? lastBackupAt;
  final bool autoBackupEnabled;

  bool get hasFolderConfigured =>
      (folderUri != null && folderUri!.isNotEmpty) ||
      (folderBookmark != null && folderBookmark!.isNotEmpty);

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': 1,
      'folder_uri': folderUri,
      'folder_bookmark': folderBookmark,
      'folder_name': folderName,
      'last_backup_at': lastBackupAt?.millisecondsSinceEpoch,
      'auto_backup_enabled': autoBackupEnabled ? 1 : 0,
    };
  }

  factory BackupSettings.fromRow(Map<String, Object?> row) {
    final int? lastBackupMs = row['last_backup_at'] as int?;
    final int? autoBackup = row['auto_backup_enabled'] as int?;
    return BackupSettings(
      folderUri: row['folder_uri'] as String?,
      folderBookmark: row['folder_bookmark'] as String?,
      folderName: row['folder_name'] as String?,
      lastBackupAt: lastBackupMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupMs)
          : null,
      autoBackupEnabled: autoBackup == null || autoBackup == 1,
    );
  }

  BackupSettings copyWith({
    String? folderUri,
    bool clearFolderUri = false,
    String? folderBookmark,
    bool clearFolderBookmark = false,
    String? folderName,
    bool clearFolderName = false,
    DateTime? lastBackupAt,
    bool clearLastBackupAt = false,
    bool? autoBackupEnabled,
  }) {
    return BackupSettings(
      folderUri: clearFolderUri ? null : (folderUri ?? this.folderUri),
      folderBookmark:
          clearFolderBookmark ? null : (folderBookmark ?? this.folderBookmark),
      folderName: clearFolderName ? null : (folderName ?? this.folderName),
      lastBackupAt:
          clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettings &&
          runtimeType == other.runtimeType &&
          folderUri == other.folderUri &&
          folderBookmark == other.folderBookmark &&
          folderName == other.folderName &&
          lastBackupAt == other.lastBackupAt &&
          autoBackupEnabled == other.autoBackupEnabled;

  @override
  int get hashCode => Object.hash(
        folderUri,
        folderBookmark,
        folderName,
        lastBackupAt,
        autoBackupEnabled,
      );
}
