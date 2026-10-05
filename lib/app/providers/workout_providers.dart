// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/workout/bloc/workout_bloc.dart';
import '../../features/workout/bloc/workout_timer_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Workout features.
/// Filled by plan 03-07; each feature Bloc reads GymStateCubit via context.read in create.
List<BlocProvider> workoutBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<WorkoutBloc>(
        create: (context) => WorkoutBloc(
          gymState: context.read<GymStateCubit>(),
          engine: deps.jsEngine,
          catalogue: deps.exerciseCatalogue,
          timer: context.read<WorkoutTimerBloc>(),
          sound: deps.timerSound,
        ),
        lazy: false,
      ),
    ];
