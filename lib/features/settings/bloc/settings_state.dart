// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/backup/backup_repository.dart';
import '../../../core/backup/backup_settings.dart';

/// Sealed base class for one-shot signals emitted by [SettingsBloc].
sealed class SettingsSignal extends Equatable {
  const SettingsSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Emitted after full data reset is committed.
final class SettingsResetDone extends SettingsSignal {
  const SettingsResetDone();
}

/// Emitted when a notification settings change fails (e.g. OS refused permission).
/// Mirrors `../openGym/frontend/src/views/Settings.jsx` MobileReminderCard toast.
final class SettingsToast extends SettingsSignal {
  const SettingsToast(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// State of [SettingsBloc].
class SettingsState extends Equatable {
  const SettingsState({
    this.seq = 0,
    this.signal,
    this.notificationsAllowed,
    this.exactAlarmsAllowed,
    this.backupSettings,
    this.lastBackupResult,
    this.isFolderAccessible = true,
  });

  final int seq;
  final SettingsSignal? signal;

  /// Whether the OS has granted notification permission (null = not yet checked).
  final bool? notificationsAllowed;

  /// Whether the OS has granted exact alarm permission (null = not checked / not applicable).
  final bool? exactAlarmsAllowed;

  /// Device-local backup settings.
  final BackupSettings? backupSettings;

  /// Result of the last backup operation.
  final BackupResult? lastBackupResult;

  /// Whether the configured backup folder is accessible.
  final bool isFolderAccessible;

  SettingsState copyWith({
    int? seq,
    SettingsSignal? signal,
    bool? notificationsAllowed,
    bool? exactAlarmsAllowed,
    BackupSettings? backupSettings,
    BackupResult? lastBackupResult,
    bool? isFolderAccessible,
  }) {
    return SettingsState(
      seq: seq ?? this.seq,
      signal: signal,
      notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
      backupSettings: backupSettings ?? this.backupSettings,
      lastBackupResult: lastBackupResult ?? this.lastBackupResult,
      isFolderAccessible: isFolderAccessible ?? this.isFolderAccessible,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        seq,
        signal,
        notificationsAllowed,
        exactAlarmsAllowed,
        backupSettings,
        lastBackupResult,
        isFolderAccessible,
      ];
}

