// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/state_parts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../sheets/equipment_profile_sheet.dart';

const Color _kTeal = Color(0xFF40C8E0);

/// Equipment profiles settings section.
///
/// Ports openGym `views/Settings.jsx` EquipmentCard (lines 635-660).
class EquipmentSection extends StatelessWidget {
  const EquipmentSection({super.key, required this.state});

  final GymState state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<EquipProfile> profiles =
        state.equipProfiles ?? const <EquipProfile>[];

    final String activeId = state.activeEquipId ??
        (profiles.isNotEmpty ? (profiles.first.id ?? '') : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(t('Equipment')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              if (profiles.isNotEmpty) ...<Widget>[
                AppRow(
                  icon: 'dumbbell',
                  iconTint: palette.acc,
                  title: Text(t('Filter by equipment')),
                  child: AppSwitch(
                    value: state.equipFilterOn == true,
                    onChanged: (bool v) {
                      context
                          .read<SettingsBloc>()
                          .add(SettingsEquipFilterToggled(v));
                    },
                  ),
                ),
                const Divider(height: 1.0),
                SelectRow<String>(
                  icon: 'list',
                  iconTint: palette.blue,
                  title: t('Active profile'),
                  value: activeId,
                  options: profiles
                      .map(
                        (EquipProfile p) => SelectOption<String>(
                          value: p.id ?? '',
                          label: p.name ?? '',
                        ),
                      )
                      .toList(),
                  onChanged: (String v) {
                    context
                        .read<SettingsBloc>()
                        .add(SettingsActiveEquipChanged(v));
                  },
                ),
                for (final EquipProfile p in profiles) ...<Widget>[
                  const Divider(height: 1.0),
                  AppRow(
                    icon: 'dumbbell',
                    iconTint: _kTeal,
                    title: Text(p.name ?? ''),
                    subtitle: Text(
                      t(
                        '{0} equipment types',
                        <Object?>[p.equipment?.length ?? 0],
                      ),
                    ),
                    accessory: AppRowAccessory.chevron,
                    onTap: () => showEquipmentProfileSheet(context, p),
                    child: AppIconButton(
                      'trash',
                      tooltip: t('Delete'),
                      color: palette.red,
                      onPressed: () async {
                        final String pId = p.id ?? '';
                        final String pName = p.name ?? '';
                        final bool confirmed = await showConfirmSheet(
                          context,
                          title: t('Delete profile?'),
                          message: t(
                            '"{0}" and its equipment list will be removed.',
                            <Object?>[pName],
                          ),
                          confirmText: t('Delete'),
                          danger: true,
                        );
                        if (confirmed && context.mounted) {
                          context.read<SettingsBloc>().add(
                                SettingsEquipProfileDeleted(pId),
                              );
                        }
                      },
                    ),
                  ),
                ],
                const Divider(height: 1.0),
              ],
              AppRow(
                icon: 'plus',
                iconTint: palette.acc,
                title: Text(t('Add equipment profile')),
                accessory: AppRowAccessory.chevron,
                onTap: () => showEquipmentProfileSheet(context, null),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 14.0),
          child: Text(
            t('Filters the exercise library and picker, and flags routine exercises that need something you don’t have in the active profile.'),
            style: TextStyle(fontSize: 13.0, color: palette.muted),
          ),
        ),
      ],
    );
  }
}
