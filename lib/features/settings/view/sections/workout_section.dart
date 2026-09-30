// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../sheets/effort_help_sheet.dart';
import '../sheets/workout_controls_sheet.dart';

/// "During a workout" settings section.
///
/// Ports openGym `views/Settings.jsx` During a workout section (lines 287-349).
/// Note: Screen wake lock and silent mode sound overrides are deferred to
/// Phase 5 (TMR-01) per openGym's platform-support gating.
class WorkoutSection extends StatelessWidget {
  const WorkoutSection({super.key, required this.state});

  final GymState state;

  static const List<SelectOption<num>> _kRestOptions = <SelectOption<num>>[
    SelectOption<num>(value: 0, label: 'Off'),
    SelectOption<num>(value: 30, label: '30s'),
    SelectOption<num>(value: 45, label: '45s'),
    SelectOption<num>(value: 60, label: '60s'),
    SelectOption<num>(value: 75, label: '75s'),
    SelectOption<num>(value: 90, label: '90s'),
    SelectOption<num>(value: 105, label: '105s'),
    SelectOption<num>(value: 120, label: '120s'),
    SelectOption<num>(value: 150, label: '150s'),
    SelectOption<num>(value: 180, label: '180s'),
    SelectOption<num>(value: 240, label: '240s'),
    SelectOption<num>(value: 300, label: '300s'),
  ];

  static const List<SelectOption<num>> _kRestPauseOptions = <SelectOption<num>>[
    SelectOption<num>(value: 10, label: '10s'),
    SelectOption<num>(value: 15, label: '15s'),
    SelectOption<num>(value: 20, label: '20s'),
    SelectOption<num>(value: 30, label: '30s'),
  ];

  @override
  Widget build(BuildContext context) {
    final JsEngineService engine = context.read<JsEngineService>();
    final String effort = engine.history.effortOf(state);

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
                options: _kRestOptions,
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
      ],
    );
  }
}
