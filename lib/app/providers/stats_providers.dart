// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/stats/bloc/stats_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Stats features.
/// Filled by plan 03.1-12.
List<BlocProvider> statsBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<StatsBloc>(
        create: (context) => StatsBloc(
          gymState: context.read<GymStateCubit>(),
          engine: deps.jsEngine,
          catalogue: deps.exerciseCatalogue,
        ),
      ),
    ];
