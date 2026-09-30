// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/catalogue/exercise_def.dart';
import '../../../core/models/state_parts.dart';

/// States for [MusclesBloc].
sealed class MusclesState extends Equatable {
  const MusclesState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial uninitialized state.
final class MusclesInitial extends MusclesState {
  const MusclesInitial();
}

/// Ready state with filtered exercise results and muscle metadata.
/// Mirrors `../openGym/frontend/src/components/MuscleExplorer.jsx`.
final class MusclesReady extends MusclesState {
  const MusclesReady({
    this.selected,
    this.q = '',
    this.bp = '',
    this.eq = '',
    this.eqOn = '',
    this.eqOpts = const <String>[],
    this.shown = 40,
    this.showAll = false,
    this.profile,
    this.muscleOrder = const <String>[],
    this.muscleNames = const <String, String>{},
    this.counts = const <String, int>{},
    this.results = const <ExerciseDef>[],
    this.primaryIds = const <String>{},
    this.bestWeights = const <String, double>{},
    this.favIds = const <String>{},
    this.body,
  });

  final String? selected;
  final String q;
  final String bp;
  final String eq;
  final String eqOn;
  final List<String> eqOpts;
  final int shown;
  final bool showAll;
  final EquipProfile? profile;
  final List<String> muscleOrder;
  final Map<String, String> muscleNames;
  final Map<String, int> counts;
  final List<ExerciseDef> results;
  final Set<String> primaryIds;
  final Map<String, double> bestWeights;
  final Set<String> favIds;
  final String? body;

  @override
  List<Object?> get props => <Object?>[
        selected,
        q,
        bp,
        eq,
        eqOn,
        eqOpts,
        shown,
        showAll,
        profile,
        muscleOrder,
        muscleNames,
        counts,
        results,
        primaryIds,
        bestWeights,
        favIds,
        body,
      ];
}
