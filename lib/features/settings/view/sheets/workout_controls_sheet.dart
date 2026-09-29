// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/workout_controls.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';

/// Opens the workout controls modal sheet.
///
/// Ports openGym `views/Settings.jsx` WorkoutControlsSheet (lines 458-486).
Future<void> showWorkoutControlsSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _WorkoutControlsSheet(),
  );
}

class _WorkoutControlsSheet extends StatelessWidget {
  const _WorkoutControlsSheet();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final WorkoutControlsView wc = workoutControls(gymState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Workout controls'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4.0),
        Text(
          t('Show or hide control groups on the workout screen.'),
          style: TextStyle(fontSize: 14.0, color: palette.muted),
        ),
        const SizedBox(height: 16.0),
        AppRow(
          title: Text(t('Weight and reps buttons')),
          subtitle: Text(t('Off: tap the number and type it')),
          child: AppSwitch(
            value: wc.steppers,
            onChanged: (bool v) {
              context.read<SettingsBloc>().add(
                    SettingsWorkoutControlsChanged('steppers', v),
                  );
            },
          ),
        ),
        AppRow(
          title: Text(t('Drop and burst shortcuts on every set')),
          child: AppSwitch(
            value: wc.setShortcuts,
            onChanged: (bool v) {
              context.read<SettingsBloc>().add(
                    SettingsWorkoutControlsChanged('setShortcuts', v),
                  );
            },
          ),
        ),
        AppRow(
          title: Text(t('Superset buttons in the exercise header')),
          child: AppSwitch(
            value: wc.pairButtons,
            onChanged: (bool v) {
              context.read<SettingsBloc>().add(
                    SettingsWorkoutControlsChanged('pairButtons', v),
                  );
            },
          ),
        ),
        AppRow(
          title: Text(t('Move, swap and remove buttons below the exercise')),
          child: AppSwitch(
            value: wc.exerciseButtons,
            onChanged: (bool v) {
              context.read<SettingsBloc>().add(
                    SettingsWorkoutControlsChanged('exerciseButtons', v),
                  );
            },
          ),
        ),
      ],
    );
  }
}
