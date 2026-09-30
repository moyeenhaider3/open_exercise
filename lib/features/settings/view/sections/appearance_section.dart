// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/theme/accents.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../shell/bloc/shell_bloc.dart';
import '../../../shell/bloc/shell_event.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';

const Color _kTeal = Color(0xFF40C8E0);

/// Appearance settings section (theme, body diagram, accent color).
///
/// Ports openGym `views/Settings.jsx` Appearance section (lines 351-379).
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.state});

  final GymState state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String currentAccent = state.accent ?? 'lime';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(t('Appearance')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppRow(
                icon: 'moon',
                iconTint: palette.purple,
                title: Text(t('Theme')),
                child: AppSegmented<String>(
                  value: state.theme ?? 'dark',
                  options: <SegmentOption<String>>[
                    SegmentOption<String>(
                      value: 'dark',
                      icon: 'moon',
                      label: t('Dark'),
                    ),
                    SegmentOption<String>(
                      value: 'light',
                      icon: 'sun',
                      label: t('Light'),
                    ),
                    SegmentOption<String>(
                      value: 'system',
                      icon: 'gear',
                      label: t('System'),
                    ),
                  ],
                  onChanged: (String v) {
                    context.read<ShellBloc>().add(ShellThemeChanged(v));
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'figureStrength',
                iconTint: _kTeal,
                title: Text(t('Body diagram')),
                child: AppSegmented<String>(
                  value: state.body == 'female' ? 'female' : 'male',
                  options: <SegmentOption<String>>[
                    SegmentOption<String>(
                      value: 'male',
                      label: t('Male'),
                    ),
                    SegmentOption<String>(
                      value: 'female',
                      label: t('Female'),
                    ),
                  ],
                  onChanged: (String v) {
                    context.read<SettingsBloc>().add(SettingsBodyChanged(v));
                  },
                ),
              ),
              const Divider(height: 1.0),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 13.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t('Accent color'),
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children:
                          kAccents.entries.map((MapEntry<String, Color> entry) {
                        final bool isSelected = currentAccent == entry.key;
                        return InkWell(
                          onTap: () {
                            context
                                .read<ShellBloc>()
                                .add(ShellAccentChanged(entry.key));
                          },
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 36.0,
                            height: 36.0,
                            padding: const EdgeInsets.all(3.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? palette.acc
                                    : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
