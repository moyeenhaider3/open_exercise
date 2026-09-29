// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/routine.dart';

/// One-shot signals emitted by [PlanBloc].
sealed class PlanSignal extends Equatable {
  const PlanSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Navigate to a newly created routine's edit screen.
final class PlanNavigateToRoutineSignal extends PlanSignal {
  const PlanNavigateToRoutineSignal(this.routineId);

  final String routineId;

  @override
  List<Object?> get props => <Object?>[routineId];
}

/// Show a transient toast.
final class PlanToastSignal extends PlanSignal {
  const PlanToastSignal(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Show a confirmation dialog before loading the starter plan over occupied days.
final class PlanConfirmStarterSignal extends PlanSignal {
  const PlanConfirmStarterSignal({
    required this.planId,
    required this.planName,
    required this.dayNames,
  });

  final String planId;
  final String planName;
  final List<String> dayNames;

  @override
  List<Object?> get props => <Object?>[planId, planName, dayNames];
}

/// State projected by [PlanBloc] from [GymStateCubit].
/// Mirrors `../openGym/frontend/src/views/Plan.jsx` derived values.
final class PlanState extends Equatable {
  const PlanState({
    required this.routines,
    required this.dayOrder,
    required this.dayRoutines,
    this.signal,
    this.seq = 0,
  });

  final List<Routine> routines;

  /// Ordered weekday indices for the current week-start setting (weekOrder(weekStartOf(s))).
  final List<int> dayOrder;

  /// Routines per weekday, stale ids dropped (Plan.jsx filter(Boolean)).
  final Map<int, List<Routine>> dayRoutines;

  final PlanSignal? signal;
  final int seq;

  PlanState withSignal(PlanSignal sig) => PlanState(
        routines: routines,
        dayOrder: dayOrder,
        dayRoutines: dayRoutines,
        signal: sig,
        seq: seq + 1,
      );

  PlanState copyWith({
    List<Routine>? routines,
    List<int>? dayOrder,
    Map<int, List<Routine>>? dayRoutines,
    PlanSignal? signal,
    int? seq,
  }) {
    return PlanState(
      routines: routines ?? this.routines,
      dayOrder: dayOrder ?? this.dayOrder,
      dayRoutines: dayRoutines ?? this.dayRoutines,
      signal: signal ?? this.signal,
      seq: seq ?? this.seq,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        routines,
        dayOrder,
        dayRoutines,
        signal,
        seq,
      ];
}
