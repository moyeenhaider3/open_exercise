// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backup/fresh_install_check.dart';
import '../../../core/js/models/phase3_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/ui_kit/toast.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_state.dart';
import 'active_workout_view.dart';
import 'sheets/finish_flow.dart';
import 'start_chooser.dart';

/// Screen managing workout lifecycle: StartChooser when idle, ActiveWorkoutView when running.
///
/// Dispatches UI signals from [WorkoutBloc] for start, all-done, toasts, finish checks,
/// and workout completion summary.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listenWhen: (WorkoutState prev, WorkoutState curr) =>
          curr.signal != null && prev.seq != curr.seq,
      listener: (BuildContext context, WorkoutState state) {
        final WorkoutSignal? signal = state.signal;
        if (signal == null) return;
        switch (signal) {
          case WorkoutStartedSignal():
            context.go(AppRoutes.workout);
          case WorkoutAllDoneSignal():
            showWorkoutCompleteSheet(context);
          case WorkoutToastSignal(:final String message):
            showToast(context, message);
          case WorkoutFinishCheckSignal(:final int done, :final int total):
            runFinishFlow(context, done: done, total: total);
          case WorkoutFinishedSignal(
              :final FinishResult result,
              :final bool isFirstWorkout
            ):
            final String unit =
                context.read<GymStateCubit>().state.unit ?? 'kg';
            showFinishSummary(context, result, unit).then((_) {
              if (isFirstWorkout && context.mounted) {
                showFirstWorkoutBackupPrompt(context);
              }
            });
        }
      },
      child: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (BuildContext context, WorkoutState state) {
          return switch (state) {
            WorkoutNone() => const StartChooser(),
            WorkoutRunning() => ActiveWorkoutView(state: state),
          };
        },
      ),
    );
  }
}
