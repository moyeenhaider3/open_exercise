// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/gym_state_cubit.dart';
import '../../features/history/bloc/history_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for History features.
/// Filled by plan 03.1-08.
List<BlocProvider> historyBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<HistoryBloc>(
        create: (context) => HistoryBloc(
          gymState: context.read<GymStateCubit>(),
          engine: deps.jsEngine,
        ),
      ),
    ];
