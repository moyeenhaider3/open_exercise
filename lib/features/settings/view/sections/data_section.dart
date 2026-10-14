// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backup/backup_import_service.dart';
import '../../../../core/backup/backup_settings.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../../plan/view/sheets/starter_plan_sheet.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../../bloc/settings_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data management settings section and application legal footer.
///
/// Ports openGym `views/Settings.jsx` Data section (lines 381-405) and footer (lines 430-438).
/// Row order (D-12):
/// Load starter plan → Import backup → Export backup (JSON) → Backup folder →
/// Auto-backup switch → Back up now → Reset everything.
class DataSection extends StatelessWidget {
  const DataSection({super.key});

  String _formatDateTime(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color actionTint = palette.acc;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (BuildContext context, SettingsState state) {
        final BackupSettings? backup = state.backupSettings;
        final bool hasFolder = backup?.hasFolderConfigured ?? false;
        final bool autoBackup =
            (backup?.autoBackupEnabled ?? false) && hasFolder;

        final bool isAccessible = state.isFolderAccessible;
        final String folderSubtitle;
        if (!hasFolder) {
          folderSubtitle = t('Not set');
        } else if (!isAccessible) {
          folderSubtitle = t('Backup folder unavailable, choose again');
        } else {
          final String name = backup?.folderName ?? t('Folder set');
          final String lastBackupStr = backup?.lastBackupAt != null
              ? _formatDateTime(backup!.lastBackupAt!)
              : t('Never');
          folderSubtitle = '$name · ${t('Last backup')}: $lastBackupStr';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(t('Data')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  // 1. Load starter plan
                  AppRow(
                    icon: 'sparkles',
                    iconTint: palette.acc,
                    title: Text(t('Load starter plan')),
                    accessory: AppRowAccessory.chevron,
                    onTap: () => showStarterPlanSheet(context),
                  ),
                  const Divider(height: 1.0),

                  // 2. Import backup
                  Builder(
                    builder: (BuildContext rowContext) {
                      return AppRow(
                        icon: 'upload',
                        iconTint: actionTint,
                        title: Text(t('Import backup')),
                        accessory: AppRowAccessory.chevron,
                        onTap: () async {
                          const BackupImportService importService =
                              BackupImportService();
                          final PickedBackupFile? picked =
                              await importService.pickBackupFileWithDetails();
                          if (picked == null) return;

                          final ImportResult result =
                              importService.validateAndPrepare(
                            picked.content,
                            picked.fileName,
                          );
                          if (!rowContext.mounted) return;

                          if (result is ImportFailure) {
                            showToast(rowContext, result.reason);
                            return;
                          }

                          if (result is ImportSuccess) {
                            final bool confirmed = await showConfirmSheet(
                              rowContext,
                              title: t('Import backup?'),
                              message: t(
                                'This replaces all current data with the backup file.',
                              ),
                              confirmText: t('Import'),
                              danger: true,
                            );
                            if (confirmed && rowContext.mounted) {
                              rowContext.read<SettingsBloc>().add(
                                    SettingsImportBackupConfirmed(result.state),
                                  );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: 1.0),

                  // 3. Export backup (JSON)
                  Builder(
                    builder: (BuildContext rowContext) {
                      return AppRow(
                        icon: 'download',
                        iconTint: actionTint,
                        title: Text(t('Export backup (JSON)')),
                        accessory: AppRowAccessory.chevron,
                        onTap: () {
                          final RenderBox? box =
                              rowContext.findRenderObject() as RenderBox?;
                          final Rect? origin = box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null;
                          rowContext.read<SettingsBloc>().add(
                                SettingsExportBackupRequested(
                                  shareOrigin: origin,
                                ),
                              );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1.0),

                  // 4. Backup folder
                  AppRow(
                    icon: 'folder',
                    iconTint: actionTint,
                    title: Text(t('Backup folder')),
                    subtitle: Text(folderSubtitle),
                    accessory: AppRowAccessory.chevron,
                    onTap: () {
                      context
                          .read<SettingsBloc>()
                          .add(const SettingsBackupFolderRequested());
                    },
                  ),
                  const Divider(height: 1.0),

                  // 5. Auto-backup switch
                  AppRow(
                    icon: 'history',
                    iconTint: actionTint,
                    title: Text(t('Auto-backup')),
                    subtitle: Text(
                      t('Back up automatically after workouts, routine changes and app backgrounding'),
                    ),
                    child: Switch(
                      value: autoBackup,
                      onChanged: hasFolder
                          ? (bool val) {
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsAutoBackupToggled(val));
                            }
                          : null,
                    ),
                  ),
                  const Divider(height: 1.0),

                  // 6. Back up now
                  AppRow(
                    icon: 'folder',
                    iconTint: actionTint,
                    title: Text(t('Back up now')),
                    subtitle:
                        hasFolder ? null : Text(t('Choose a folder first')),
                    accessory: AppRowAccessory.chevron,
                    onTap: () {
                      context
                          .read<SettingsBloc>()
                          .add(const SettingsBackupNowRequested());
                    },
                  ),
                  const Divider(height: 1.0),

                  // 7. Reset everything
                  AppRow(
                    icon: 'trash',
                    iconTint: palette.red,
                    title: Text(t('Reset everything')),
                    danger: true,
                    onTap: () async {
                      final bool confirmed = await showConfirmSheet(
                        context,
                        title: t('Reset everything?'),
                        message: t(
                          'Deletes your plan, workouts and body weight on this device. This cannot be undone.',
                        ),
                        confirmText: t('Delete everything'),
                        danger: true,
                      );
                      if (confirmed && context.mounted) {
                        context
                            .read<SettingsBloc>()
                            .add(const SettingsResetConfirmed());
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'OpenGym v1.0.0 · AGPL-3.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: palette.dim,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://moyeenhaider3.github.io/open_exercise/terms.html',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'Legal Notices & Attribution',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.0,
                        color: palette.acc,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
