// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';
import '../data/active_exercise_swap.dart';

/// Sealed base class for all events handled by [WorkoutBloc].
sealed class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Internal event fired when [GymStateCubit] emits a new state.
final class WorkoutGymStateChanged extends WorkoutEvent {
  const WorkoutGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Dispatched to begin a workout (freestyle or based on one or more routine IDs).
/// Ported from `../openGym/frontend/src/sheets.jsx`:1804-1832 beginWorkout and BwSheet.save.
final class WorkoutStartRequested extends WorkoutEvent {
  const WorkoutStartRequested({
    this.routineIds = const <String>[],
    this.bw,
  });

  final List<String> routineIds;
  final num? bw;

  @override
  List<Object?> get props => <Object?>[routineIds, bw];
}

/// Dispatched when the user taps Finish in the workout header to trigger completion checks.
/// Ported from `../openGym/frontend/src/sheets.jsx`:2179 finishWorkout.
final class WorkoutFinishRequested extends WorkoutEvent {
  const WorkoutFinishRequested();
}

/// Dispatched after user confirms finishing the workout (dialog confirmed).
/// Ported from `../openGym/frontend/src/sheets.jsx`:2200-2228 doFinishWorkout.
final class WorkoutFinishConfirmed extends WorkoutEvent {
  const WorkoutFinishConfirmed();
}

/// Dispatched to discard the active workout without saving to history.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:982.
final class WorkoutDiscarded extends WorkoutEvent {
  const WorkoutDiscarded();
}

/// Dispatched to rename the active workout session.
/// Ported from `../openGym/frontend/src/sheets.jsx`:2105-2130 RenameWorkout.save.
final class WorkoutRenamed extends WorkoutEvent {
  const WorkoutRenamed(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

/// Dispatched to update the session-level note.
/// Ported from `../openGym/frontend/src/sheets.jsx`:2078-2100 SessionNote.save.
final class WorkoutSessionNoteChanged extends WorkoutEvent {
  const WorkoutSessionNoteChanged(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

/// Dispatched to save an exercise-level note (today's note, pin setting, standing note).
/// Ported from `../openGym/frontend/src/sheets.jsx`:2019-2050 ExerciseNote.save.
final class WorkoutExerciseNoteSaved extends WorkoutEvent {
  const WorkoutExerciseNoteSaved({
    required this.entryIdx,
    required this.today,
    required this.pin,
    required this.standing,
  });

  final int entryIdx;
  final String today;
  final bool pin;
  final String standing;

  @override
  List<Object?> get props => <Object?>[entryIdx, today, pin, standing];
}

/// Dispatched to change workout layout view mode ('cards', 'list', 'compact').
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:735 setWorkoutView.
final class WorkoutViewChanged extends WorkoutEvent {
  const WorkoutViewChanged(this.view);

  final String view;

  @override
  List<Object?> get props => <Object?>[view];
}

/// Dispatched to focus a specific unit index (e.g. from List mode header).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:729 focusUnit.
final class WorkoutUnitFocused extends WorkoutEvent {
  const WorkoutUnitFocused(this.firstIdx);

  final int firstIdx;

  @override
  List<Object?> get props => <Object?>[firstIdx];
}

/// Dispatched to navigate to previous (-1) or next (+1) unit.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:716 navigateUnit.
final class WorkoutUnitNavigated extends WorkoutEvent {
  const WorkoutUnitNavigated(this.direction);

  final int direction;

  @override
  List<Object?> get props => <Object?>[direction];
}

/// Dispatched to move a unit up (-1) or down (+1) in the workout order.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:673 moveUnitAt.
final class WorkoutUnitMoved extends WorkoutEvent {
  const WorkoutUnitMoved({
    required this.at,
    required this.direction,
  });

  final int at;
  final int direction;

  @override
  List<Object?> get props => <Object?>[at, direction];
}

/// Dispatched to pair two adjacent exercises into a superset.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:663 pairAt.
final class WorkoutPaired extends WorkoutEvent {
  const WorkoutPaired({
    required this.first,
    required this.second,
  });

  final int first;
  final int second;

  @override
  List<Object?> get props => <Object?>[first, second];
}

/// Dispatched to unpair an exercise from its superset group.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:666 unpairAt.
final class WorkoutUnpaired extends WorkoutEvent {
  const WorkoutUnpaired(this.idx);

  final int idx;

  @override
  List<Object?> get props => <Object?>[idx];
}

/// Dispatched to add an exercise to the active workout session.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:1066-1096.
final class WorkoutExerciseAdded extends WorkoutEvent {
  const WorkoutExerciseAdded({
    required this.exId,
    required this.cfg,
    this.quick = false,
  });

  final String exId;
  final RoutineExercise cfg;
  final bool quick;

  @override
  List<Object?> get props => <Object?>[exId, cfg, quick];
}

/// Dispatched to swap an exercise in the active workout session.
/// Ported from `../openGym/frontend/src/sheets.jsx`:1005-1075 swapActiveWorkoutExercise.
final class WorkoutExerciseSwapped extends WorkoutEvent {
  const WorkoutExerciseSwapped({
    required this.index,
    required this.exId,
    required this.cfg,
    this.options = const SwapOptions(),
  });

  final int index;
  final String exId;
  final RoutineExercise cfg;
  final SwapOptions options;

  @override
  List<Object?> get props => <Object?>[index, exId, cfg, options];
}

/// Dispatched to remove an exercise from the active workout session.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:496-515 removeActiveExercise.
final class WorkoutExerciseRemoved extends WorkoutEvent {
  const WorkoutExerciseRemoved(this.idx);

  final int idx;

  @override
  List<Object?> get props => <Object?>[idx];
}

/// Dispatched to add an entire routine to the active session.
/// Ported from `../openGym/frontend/src/sheets.jsx`:1913-1946 AddRoutineToSession.add.
final class WorkoutRoutineAddedToSession extends WorkoutEvent {
  const WorkoutRoutineAddedToSession(this.routineId);

  final String routineId;

  @override
  List<Object?> get props => <Object?>[routineId];
}
