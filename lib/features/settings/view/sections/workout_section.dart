// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../sheets/effort_help_sheet.dart';
import '../sheets/workout_controls_sheet.dart';

/// "During a workout" settings section.
///
/// Ports openGym `views/Settings.jsx` During a workout section (lines 271-335).
class WorkoutSection extends StatelessWidget {
  const WorkoutSection({super.key, required this.state});

  final GymState state;

  /// openGym Settings.jsx:293-295 rest timer options: Off, 60, 90, 120, 150, 180.
  static const List<SelectOption<num>> _kRestOptions = <SelectOption<num>>[
    SelectOption<num>(value: 0, label: 'Off'),
    SelectOption<num>(value: 60, label: '60s'),
    SelectOption<num>(value: 90, label: '90s'),
    SelectOption<num>(value: 120, label: '120s'),
    SelectOption<num>(value: 150, label: '150s'),
    SelectOption<num>(value: 180, label: '180s'),
  ];

  static const List<SelectOption<num>> _kRestPauseOptions = <SelectOption<num>>[
    SelectOption<num>(value: 10, label: '10s'),
    SelectOption<num>(value: 15, label: '15s'),
    SelectOption<num>(value: 20, label: '20s'),
    SelectOption<num>(value: 30, label: '30s'),
  ];

  /// Returns the rest options to pass to SelectRow. If the stored value is not
  /// in _kRestOptions (e.g. a value from older state or an import), shows the stored
  /// value as its label without adding it to the list and without changing the stored value.
  List<SelectOption<num>> _effectiveRestOptions(num? restSec) {
    final num value = restSec ?? 90;
    final bool inList = _kRestOptions.any((SelectOption<num> o) => o.value == value);
    if (inList) return _kRestOptions;
    // Prepend the stored value as a display-only option
    return <SelectOption<num>>[
      SelectOption<num>(value: value, label: '${value}s'),
      ..._kRestOptions,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final String effort = engine.history.effortOf(state);

    // On mobile, wakelock is always supported (wakeOK in openGym)
    final bool wakeOK = !kIsWeb;
    // Play-on-silent only on iOS (openGym playOnSilentSupported: iPhone/iPad only)
    final bool playOnSilentSupported = !kIsWeb && Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(t('During a workout')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              AppRow(
                icon: 'scale',
                title: Text(t('Weigh in before workouts')),
                subtitle: Text(t('Ask for your body weight when starting a workout.')),
                child: AppSwitch(
                  value: state.weighIn != false,
                  onChanged: (bool v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(weighIn: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'grid',
                title: Text(t('Workout view')),
                child: AppSegmented<String>(
                  value: state.workoutView == 'list' || state.workoutView == 'compact'
                      ? state.workoutView!
                      : 'cards',
                  options: <SegmentOption<String>>[
                    SegmentOption<String>(value: 'cards', label: t('Cards')),
                    SegmentOption<String>(value: 'list', label: t('List')),
                    SegmentOption<String>(value: 'compact', label: t('Compact')),
                  ],
                  onChanged: (String v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(workoutView: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'controls',
                title: Text(t('Workout controls')),
                subtitle: Text(t('Choose which buttons to show on the workout screen.')),
                accessory: AppRowAccessory.chevron,
                onTap: () => showWorkoutControlsSheet(context),
              ),
              const Divider(height: 1.0),
              SelectRow<num>(
                icon: 'stopwatch',
                title: t('Rest timer'),
                value: state.restSec ?? 90,
                options: _effectiveRestOptions(state.restSec),
                onChanged: (num v) {
                  context.read<SettingsBloc>().add(
                        SettingsWorkoutChanged(restSec: v),
                      );
                },
              ),
              const Divider(height: 1.0),
              SelectRow<num>(
                icon: 'timer',
                title: t('Rest-pause rest'),
                value: state.restPauseSec ?? 15,
                options: _kRestPauseOptions,
                onChanged: (num v) {
                  context.read<SettingsBloc>().add(
                        SettingsWorkoutChanged(restPauseSec: v),
                      );
                },
              ),
              const Divider(height: 1.0),
              // Keep screen awake — always enabled on mobile (wakeOK)
              if (wakeOK) ...<Widget>[
                AppRow(
                  icon: 'sun',
                  title: Text(t('Keep screen awake')),
                  child: AppSwitch(
                    value: state.keepAwake != false,
                    onChanged: (bool v) {
                      context.read<SettingsBloc>().add(
                            SettingsWorkoutChanged(keepAwake: v),
                          );
                    },
                  ),
                ),
                const Divider(height: 1.0),
              ],
              AppRow(
                icon: 'film',
                title: Text(t('Exercise animations')),
                child: AppSegmented<String>(
                  value: state.gifSize == 'mini' || state.gifSize == 'off'
                      ? state.gifSize!
                      : 'full',
                  options: <SegmentOption<String>>[
                    SegmentOption<String>(value: 'full', label: t('Full')),
                    SegmentOption<String>(value: 'mini', label: t('Small')),
                    SegmentOption<String>(value: 'off', label: t('Hidden')),
                  ],
                  onChanged: (String v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(gifSize: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'speaker',
                title: Text(t('Sounds')),
                child: AppSwitch(
                  value: state.sound ?? true,
                  onChanged: (bool v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(sound: v),
                        );
                  },
                ),
              ),
              // Play sounds when on silent — iOS only, when Sounds is on
              if (state.sound == true && playOnSilentSupported) ...<Widget>[
                const Divider(height: 1.0),
                AppRow(
                  icon: 'bell',
                  title: Text(t('Play sounds when the phone is on silent')),
                  subtitle: Text(
                    t('Music playing on this phone stops during a workout and does not resume by itself.'),
                  ),
                  child: AppSwitch(
                    value: state.soundOnSilent == true,
                    onChanged: (bool v) {
                      context.read<SettingsBloc>().add(
                            SettingsWorkoutChanged(soundOnSilent: v),
                          );
                    },
                  ),
                ),
              ],
              const Divider(height: 1.0),
              AppRow(
                icon: 'flash',
                title: Text(t('Flash screen when timer ends')),
                child: AppSwitch(
                  value: state.timerFlash ?? false,
                  onChanged: (bool v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(timerFlash: v),
                        );
                  },
                ),
              ),
              const Divider(height: 1.0),
              AppRow(
                icon: 'gauge',
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        t('Effort per set'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    AppIconButton(
                      'info',
                      tooltip: t('Effort scale'),
                      small: true,
                      onPressed: () => showEffortHelpSheet(context),
                    ),
                  ],
                ),
                child: AppSegmented<String>(
                  value: effort,
                  options: <SegmentOption<String>>[
                    SegmentOption<String>(value: 'none', label: t('Off')),
                    const SegmentOption<String>(value: 'rir', label: 'RIR'),
                    const SegmentOption<String>(value: 'rpe', label: 'RPE'),
                  ],
                  onChanged: (String v) {
                    context.read<SettingsBloc>().add(
                          SettingsWorkoutChanged(effort: v),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
        // Section footer — Settings.jsx During a workout footer (line 271)
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 14.0),
          child: Text(
            t("The screen stays on while a workout is running, so you don't have to unlock your phone between sets."),
            style: TextStyle(fontSize: 13.0, color: palette.muted),
          ),
        ),
      ],
    );
  }
}
