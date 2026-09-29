// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';

/// General settings section (unit, decimals, week start, check-in).
///
/// Ports openGym `views/Settings.jsx` General section (lines 234-285).
/// Note: Language selection is deferred to Phase 8 per project plan.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.state});

  final GymState state;

  void _onUnitChanged(BuildContext context, String newUnit) {
    if (newUnit == state.unit) return;

    showMenuSheet(
      context,
      title: t('Convert to {0}?', <Object?>[newUnit]),
      subtitle: t(
        'Every stored weight — logged sets, working weights, routine targets, body weight, bar weights — is in {0}. Convert the numbers, or keep them and only change the label?',
        <Object?>[state.unit ?? 'kg'],
      ),
      items: <MenuItemSpec>[
        MenuItemSpec(
          icon: 'shuffle',
          label: t('Convert the numbers'),
          onTap: () {
            Navigator.of(context).pop();
            context.read<SettingsBloc>().add(
                  SettingsUnitSwitched(newUnit, convert: true),
                );
          },
        ),
        MenuItemSpec(
          icon: 'pencil',
          label: t('Keep the numbers, change the label'),
          onTap: () {
            Navigator.of(context).pop();
            context.read<SettingsBloc>().add(
                  SettingsUnitSwitched(newUnit, convert: false),
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(t('General')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              AppRow(
                icon: 'scale',
                title: Text(t('Weight unit')),
                child: AppSegmented<String>(
                  value: state.unit ?? 'kg',
                  options: const <SegmentOption<String>>[
                    SegmentOption<String>(value: 'kg', label: 'kg'),
                    SegmentOption<String>(value: 'lb', label: 'lb'),
                  ],
                  onChanged: (String v) => _onUnitChanged(context, v),
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'hashtag',
                title: Text(t('Weight decimals')),
                subtitle: Text(t('How precisely weights are shown.')),
                child: AppSegmented<int>(
                  value: state.wdec == 2 ? 2 : 1,
                  options: const <SegmentOption<int>>[
                    SegmentOption<int>(value: 1, label: '0.5'),
                    SegmentOption<int>(value: 2, label: '0.25'),
                  ],
                  onChanged: (int v) {
                    context.read<SettingsBloc>().add(
                          SettingsGeneralChanged(wdec: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'calendar',
                title: Text(t('Week starts on')),
                child: AppSegmented<int>(
                  value: weekStartOf(state),
                  options: <SegmentOption<int>>[
                    SegmentOption<int>(value: kMonday, label: t('Monday')),
                    SegmentOption<int>(value: kSunday, label: t('Sunday')),
                  ],
                  onChanged: (int v) {
                    context.read<SettingsBloc>().add(
                          SettingsGeneralChanged(weekStart: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'barcode',
                title: Text(t('Gym check-in')),
                subtitle: Text(t('Show a card on Home with your membership QR codes.')),
                child: AppSwitch(
                  value: state.checkIn != false,
                  onChanged: (bool v) {
                    context.read<SettingsBloc>().add(
                          SettingsGeneralChanged(checkIn: v),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 14.0),
          child: Text(
            t('Switching the unit offers to convert every stored weight.'),
            style: TextStyle(fontSize: 13.0, color: palette.muted),
          ),
        ),
      ],
    );
  }
}
