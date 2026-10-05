// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/workout/bloc/workout_timer_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for timer features.
/// Consumed by [OpenExerciseApp] before workoutBlocProviders so that
/// WorkoutBloc (05-07) can read [WorkoutTimerBloc] via context.read.
List<BlocProvider> timerBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<WorkoutTimerBloc>(
        lazy: false,
        create: (context) => WorkoutTimerBloc(
          gymState: context.read<GymStateCubit>(),
          notifications: deps.notificationService,
          sound: deps.timerSound,
        ),
      ),
    ];
