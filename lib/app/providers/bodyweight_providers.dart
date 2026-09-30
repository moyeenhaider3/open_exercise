// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/bodyweight/bloc/bodyweight_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Bodyweight features.
/// Filled by plan 03.1-09.
List<BlocProvider> bodyweightBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<BodyweightBloc>(
        create: (context) => BodyweightBloc(
          gymState: context.read<GymStateCubit>(),
        ),
      ),
    ];
