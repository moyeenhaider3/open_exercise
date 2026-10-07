// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/gym_state_cubit.dart';
import 'backup_repository.dart';
import 'backup_settings.dart';
import 'backup_settings_dao.dart';

/// Manages auto-backup triggers: detects state changes and fires
/// backup on app-background transitions (D-06c), workout finish (D-06a),
/// and routine editor exit (D-06b).
///
/// Ports openGym's autoBackupNow() guard:
/// `if (MOBILE && S.autoBackup) writeAutoBackup(S)`
final class AutoBackupSync {
  AutoBackupSync({
    required this.backupRepository,
    required this.gymState,
    required this.settingsDao,
  });

  final BackupRepository backupRepository;
  final GymStateCubit gymState;
  final BackupSettingsDao settingsDao;

  AppLifecycleListener? _lifecycleListener;
  num? _lastBackupTs;

  /// Called once at app start. Sets up the AppLifecycleListener.
  void init() {
    _lifecycleListener = AppLifecycleListener(
      onInactive: _onAppBackground,
    );
    _lastBackupTs = gymState.state.ts;
  }

  /// Fire-and-forget backup. Called from workout finish and routine editor exit.
  /// No-op if auto-backup disabled or no folder configured.
  Future<void> autoBackupNow() async {
    try {
      final BackupSettings settings = await settingsDao.load();
      if (!settings.autoBackupEnabled || !settings.hasFolderConfigured) return;
      if (gymState.state.autoBackup != true) return;
      await backupRepository.backupNow();
      _lastBackupTs = gymState.state.ts;
    } catch (_) {
      // D-04: fail silently in background
    }
  }

  /// D-06(c): backup on app background if state changed.
  void _onAppBackground() {
    if (gymState.state.ts != _lastBackupTs) {
      unawaited(autoBackupNow());
    }
  }

  void dispose() {
    _lifecycleListener?.dispose();
  }
}
