// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/js/models/muscle_models.dart';

sealed class MuscleBalanceState extends Equatable {
  const MuscleBalanceState();

  @override
  List<Object?> get props => <Object?>[];
}

final class MuscleBalanceReady extends MuscleBalanceState {
  const MuscleBalanceReady({
    required this.view,
    required this.win,
    required this.hard,
    this.selected,
    this.body,
    required this.unit,
    required this.balance,
    required this.fatigue,
    required this.strength,
    required this.muscleNames,
  });

  final String view;
  final int win;
  final bool hard;
  final String? selected;
  final String? body;
  final String unit;
  final MuscleBalanceView balance;
  final FatigueView fatigue;
  final StrengthView strength;
  final Map<String, String> muscleNames;

  @override
  List<Object?> get props => <Object?>[
        view,
        win,
        hard,
        selected,
        body,
        unit,
        balance,
        fatigue,
        strength,
        muscleNames,
      ];
}
