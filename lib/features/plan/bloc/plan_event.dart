// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Sealed base class for all events handled by [PlanBloc].
sealed class PlanEvent extends Equatable {
  const PlanEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Internal event fired when [GymStateCubit] emits a new state.
final class PlanGymStateChanged extends PlanEvent {
  const PlanGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Dispatched to add a new empty routine and navigate to it.
/// Ported from `../openGym/frontend/src/views/Plan.jsx` addRoutine.
final class PlanRoutineAdded extends PlanEvent {
  const PlanRoutineAdded();
}

/// Dispatched to move a routine up (-1) or down (+1) in the list.
/// Ported from `../openGym/frontend/src/views/Plan.jsx` moveRoutine.
final class PlanRoutineMoved extends PlanEvent {
  const PlanRoutineMoved(this.index, this.delta);

  final int index;
  final int delta;

  @override
  List<Object?> get props => <Object?>[index, delta];
}

/// Dispatched to assign a single routine to a weekday (null/empty clears the day).
/// Ported from `../openGym/frontend/src/sheets.jsx` DayAssign.set.
final class PlanDayAssigned extends PlanEvent {
  const PlanDayAssigned(this.day, this.routineId);

  final int day;
  final String? routineId;

  @override
  List<Object?> get props => <Object?>[day, routineId];
}

/// Dispatched to append a routine to a populated weekday.
/// Ported from `../openGym/frontend/src/sheets.jsx` DayAddRoutine.add.
final class PlanDayRoutineAdded extends PlanEvent {
  const PlanDayRoutineAdded(this.day, this.routineId);

  final int day;
  final String routineId;

  @override
  List<Object?> get props => <Object?>[day, routineId];
}

/// Dispatched to remove a routine from a weekday.
/// Ported from `../openGym/frontend/src/views/Plan.jsx` removeFromDay.
final class PlanDayRoutineRemoved extends PlanEvent {
  const PlanDayRoutineRemoved(this.day, this.routineId);

  final int day;
  final String routineId;

  @override
  List<Object?> get props => <Object?>[day, routineId];
}

/// Dispatched to check if a starter plan's days are taken; if so, signal confirm first.
/// Ported from `../openGym/frontend/src/sheets.jsx` StarterPlanChooser.choose.
final class PlanStarterLoadRequested extends PlanEvent {
  const PlanStarterLoadRequested(this.planId);

  final String planId;

  @override
  List<Object?> get props => <Object?>[planId];
}

/// Dispatched after the user confirms loading a starter plan.
/// Ported from `../openGym/frontend/src/sheets.jsx` loadStarterPlan.
final class PlanStarterLoaded extends PlanEvent {
  const PlanStarterLoaded(this.planId);

  final String planId;

  @override
  List<Object?> get props => <Object?>[planId];
}

/// Dispatched to set or clear a date override in dayPlan.
/// Ported from `../openGym/frontend/src/sheets.jsx` DayOverride.set.
final class PlanDayOverrideSet extends PlanEvent {
  const PlanDayOverrideSet(this.iso, this.value);

  final String iso;
  final String value;

  @override
  List<Object?> get props => <Object?>[iso, value];
}

