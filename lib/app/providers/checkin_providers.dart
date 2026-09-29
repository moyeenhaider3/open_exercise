// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/checkin/bloc/checkin_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Check-in features.
/// Filled by plan 03.1-06.
List<BlocProvider> checkinBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<CheckInBloc>(
        create: (context) => CheckInBloc(
          gymState: context.read<GymStateCubit>(),
        ),
      ),
    ];
