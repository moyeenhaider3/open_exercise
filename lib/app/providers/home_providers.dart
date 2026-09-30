// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/home/bloc/home_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Home features.
/// Filled by plan 03.1-11.
List<BlocProvider> homeBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<HomeBloc>(
        create: (context) => HomeBloc(
          gymState: context.read<GymStateCubit>(),
          engine: deps.jsEngine,
        ),
      ),
    ];
