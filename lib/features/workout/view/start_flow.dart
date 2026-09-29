// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/gym_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import 'sheets/weigh_in_sheet.dart';

/// Initiates workout session entry, adhering to the user's weigh-in preference.
///
/// Ported from `../openGym/frontend/src/sheets.jsx` lines 1804-1832 startFlow.
Future<void> startFlow(BuildContext context, List<String> routineIds) async {
  final GymState state = context.read<GymStateCubit>().state;

  // The weigh-in is a setting (Settings -> During a workout): false goes straight
  // into the session with no body weight on it, same as "Start without weighing in".
  if (state.weighIn == false) {
    context.read<WorkoutBloc>().add(
          WorkoutStartRequested(routineIds: routineIds, bw: null),
        );
    return;
  }

  final WeighInResult result = await showWeighInSheet(context);
  if (!context.mounted) return;

  switch (result) {
    case WeighInSaved(:final num bw):
      context.read<WorkoutBloc>().add(
            WorkoutStartRequested(routineIds: routineIds, bw: bw),
          );
    case WeighInSkipped():
      context.read<WorkoutBloc>().add(
            WorkoutStartRequested(routineIds: routineIds, bw: null),
          );
    case WeighInChooseDifferent():
      context.go(AppRoutes.workout);
    case WeighInCancelled():
      break;
  }
}
