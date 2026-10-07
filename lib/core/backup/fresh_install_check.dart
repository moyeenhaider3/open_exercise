// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../i18n/t.dart';
import '../models/gym_state.dart';
import '../state/gym_state_cubit.dart';
import '../ui_kit/buttons.dart';
import '../ui_kit/modals.dart';
import '../ui_kit/toast.dart';
import 'backup_import_service.dart';
import 'backup_repository.dart';
import 'backup_settings.dart';

bool _freshInstallChecked = false;
bool _folderUnavailableSnackbarShown = false;

/// Checks if this is a fresh install (no workouts, no routines) and offers
/// "Restore from a backup?" sheet once per process run (D-14).
Future<void> checkFreshInstall(BuildContext context) async {
  if (_freshInstallChecked) return;
  _freshInstallChecked = true;

  final GymStateCubit cubit = context.read<GymStateCubit>();
  final GymState state = cubit.state;

  final bool hasWorkouts =
      state.workouts != null && state.workouts!.isNotEmpty;
  final bool hasRoutines =
      state.routines != null && state.routines!.isNotEmpty;
  if (hasWorkouts || hasRoutines) {
    return;
  }

  await showAppSheet<void>(
    context,
    (BuildContext sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('Restore from a backup?'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('If you have a backup from openGym or this app, you can restore it now.'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: Text(t('Pick file')),
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                const BackupImportService importService =
                    BackupImportService();
                final PickedBackupFile? picked =
                    await importService.pickBackupFileWithDetails();
                if (picked == null || !context.mounted) return;

                final ImportResult result = importService.validateAndPrepare(
                  picked.content,
                  picked.fileName,
                );
                if (!context.mounted) return;

                if (result is ImportFailure) {
                  showToast(context, result.reason);
                  return;
                }

                if (result is ImportSuccess) {
                  final bool confirmed = await showConfirmSheet(
                    context,
                    title: t('Import backup?'),
                    message: t(
                      'This replaces all current data with the backup file.',
                    ),
                    confirmText: t('Import'),
                    danger: true,
                  );
                  if (confirmed && context.mounted) {
                    cubit.replaceState(result.state);
                    await cubit.flush();
                    if (context.mounted) {
                      showToast(context, t('Backup imported'));
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: Text(t('Start fresh')),
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );
}

/// Checks if configured backup folder is accessible once per launch (D-04).
/// Shows snackbar if inaccessible.
Future<void> checkBackupFolderAccessible(BuildContext context) async {
  if (_folderUnavailableSnackbarShown) return;
  _folderUnavailableSnackbarShown = true;

  final BackupRepository backupRepo = context.read<BackupRepository>();
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final BackupSettings settings = await backupRepo.getSettings();
  if (!settings.hasFolderConfigured) return;

  final bool accessible = await backupRepo.folderService.isFolderAccessible();
  if (!accessible) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t('Backup folder unavailable — choose again in Settings'),
        ),
      ),
    );
  }
}

/// Prompts user to choose a backup folder after their first finished workout (D-02).
Future<void> showFirstWorkoutBackupPrompt(BuildContext context) async {
  final BackupRepository backupRepo = context.read<BackupRepository>();
  final BackupSettings settings = await backupRepo.getSettings();
  if (settings.hasFolderConfigured) return;
  if (!context.mounted) return;

  await showAppSheet<void>(
    context,
    (BuildContext sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('Your first workout is saved!'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('Choose a folder to back up your data automatically.'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: Text(t('Choose folder')),
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                final String? picked = await backupRepo.pickFolder();
                if (picked != null && context.mounted) {
                  context.read<GymStateCubit>().mutate(
                        (GymState s) => s.copyWith(autoBackup: true),
                      );
                  showToast(context, t('Backup folder set'));
                }
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: Text(t('Skip')),
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );
}
