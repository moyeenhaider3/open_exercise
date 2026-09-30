// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../plan/view/sheets/starter_plan_sheet.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';

/// Data management settings section and application legal footer.
///
/// Ports openGym `views/Settings.jsx` Data section (lines 381-405) and footer (lines 430-438).
/// Note: Backup export/import and sync are deferred to Phase 8 per project plan.
class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(t('Data')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              AppRow(
                icon: 'sparkles',
                iconTint: palette.acc,
                title: Text(t('Load starter plan')),
                accessory: AppRowAccessory.chevron,
                onTap: () => showStarterPlanSheet(context),
              ),
              const Divider(height: 1.0),
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
                'open_exercise v1.0.0 · free & open source (AGPL v3)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.dim,
                  height: 1.6,
                ),
              ),
              Text(
                'Native Flutter port of openGym (gitlab.com/DuarteSantos8/opengym)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.dim,
                  height: 1.6,
                ),
              ),
              Text(
                'exercise data: hasaneyldrm/exercises-dataset (MIT)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.dim,
                  height: 1.6,
                ),
              ),
              Text(
                'exercise images and animations © Gym visual',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.dim,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
