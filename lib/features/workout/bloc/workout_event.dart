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

/// Dispatched to log a past workout session (backfill).
/// Ported from `../openGym/frontend/src/sheets.jsx`:1890-1907 beginBackfill.
final class WorkoutBackfillStarted extends WorkoutEvent {
  const WorkoutBackfillStarted({
    required this.iso,
    required this.time,
    required this.durationMin,
    this.routineId,
    this.replaceId,
  });

  final String iso;
  final String time;
  final int durationMin;
  final String? routineId;
  final String? replaceId;

  @override
  List<Object?> get props => <Object?>[iso, time, durationMin, routineId, replaceId];
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

/// Dispatched to update a single field on a set row (or cascade weight when field is 'w').
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:629-637 setField.
final class WorkoutSetFieldChanged extends WorkoutEvent {
  const WorkoutSetFieldChanged(this.entryIdx, this.setIdx, this.field, this.value);

  final int entryIdx;
  final int setIdx;
  final String field;
  final num? value;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, field, value];
}

/// Dispatched when stepping a set field up (+1) or down (-1).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:174-180 bump, 286-294 sideBump.
final class WorkoutSetFieldBumped extends WorkoutEvent {
  const WorkoutSetFieldBumped(
    this.entryIdx,
    this.setIdx,
    this.field,
    this.direction,
    this.step, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final String field;
  final int direction;
  final num step;
  final String? side;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, field, direction, step, side];
}

/// Dispatched to add a new set to an exercise in the active workout.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:639-654 addSet.
final class WorkoutSetAdded extends WorkoutEvent {
  const WorkoutSetAdded(this.entryIdx);

  final int entryIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx];
}

/// Dispatched to remove the last set of an exercise (if more than 1 set exists).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:655 removeSet.
final class WorkoutSetRemoved extends WorkoutEvent {
  const WorkoutSetRemoved(this.entryIdx);

  final int entryIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx];
}

/// Dispatched to insert a warm-up row ramping toward the work weight.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:656-659 addWarmup.
final class WorkoutWarmupAdded extends WorkoutEvent {
  const WorkoutWarmupAdded(this.entryIdx);

  final int entryIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx];
}

/// Dispatched to remove a specific set row by index.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:660 removeSetAt.
final class WorkoutSetRemovedAt extends WorkoutEvent {
  const WorkoutSetRemovedAt(this.entryIdx, this.setIdx);

  final int entryIdx;
  final int setIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx];
}

/// Dispatched to add a drop-set row to a set.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:87-97 addDropRow.
final class WorkoutDropAdded extends WorkoutEvent {
  const WorkoutDropAdded(this.entryIdx, this.setIdx);

  final int entryIdx;
  final int setIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx];
}

/// Dispatched to add a rest-pause cluster burst to a set.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:101-108 addBurstRow.
final class WorkoutBurstAdded extends WorkoutEvent {
  const WorkoutBurstAdded(this.entryIdx, this.setIdx);

  final int entryIdx;
  final int setIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx];
}

/// Dispatched when stepping a drop-set field up (+1) or down (-1).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:346-347, 361-367 miniStepper.
final class WorkoutDropFieldBumped extends WorkoutEvent {
  const WorkoutDropFieldBumped(
    this.entryIdx,
    this.setIdx,
    this.dropIdx,
    this.field,
    this.direction,
    this.step, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final int dropIdx;
  final String field;
  final int direction;
  final num step;
  final String? side;

  @override
  List<Object?> get props => <Object?>[
        entryIdx,
        setIdx,
        dropIdx,
        field,
        direction,
        step,
        side,
      ];
}

/// Dispatched when stepping a rest-pause burst reps count up (+1) or down (-1).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:351, 361-367 miniStepper.
final class WorkoutBurstFieldBumped extends WorkoutEvent {
  const WorkoutBurstFieldBumped(
    this.entryIdx,
    this.setIdx,
    this.clusterIdx,
    this.direction, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final int clusterIdx;
  final int direction;
  final String? side;

  @override
  List<Object?> get props => <Object?>[
        entryIdx,
        setIdx,
        clusterIdx,
        direction,
        side,
      ];
}

/// Dispatched to remove a drop-set row by index.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:113 removeDrop.
final class WorkoutDropRemoved extends WorkoutEvent {
  const WorkoutDropRemoved(this.entryIdx, this.setIdx, this.dropIdx);

  final int entryIdx;
  final int setIdx;
  final int dropIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, dropIdx];
}

/// Dispatched to remove a rest-pause burst row by index.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:114-118 removeCluster.
final class WorkoutBurstRemoved extends WorkoutEvent {
  const WorkoutBurstRemoved(this.entryIdx, this.setIdx, this.clusterIdx);

  final int entryIdx;
  final int setIdx;
  final int clusterIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, clusterIdx];
}

/// Dispatched to change a field value on a drop-set row.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:119 setDropField.
final class WorkoutDropFieldChanged extends WorkoutEvent {
  const WorkoutDropFieldChanged(
    this.entryIdx,
    this.setIdx,
    this.dropIdx,
    this.field,
    this.value, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final int dropIdx;
  final String field;
  final num? value;
  final String? side;

  @override
  List<Object?> get props => <Object?>[
        entryIdx,
        setIdx,
        dropIdx,
        field,
        value,
        side,
      ];
}

/// Dispatched to change reps on a rest-pause burst row.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:121-125 setClusterField.
final class WorkoutBurstFieldChanged extends WorkoutEvent {
  const WorkoutBurstFieldChanged(
    this.entryIdx,
    this.setIdx,
    this.clusterIdx,
    this.value, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final int clusterIdx;
  final num? value;
  final String? side;

  @override
  List<Object?> get props => <Object?>[
        entryIdx,
        setIdx,
        clusterIdx,
        value,
        side,
      ];
}

/// Dispatched to change a field value on a single side ('L' or 'R') of a unilateral set.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:110 setSide.
final class WorkoutSideFieldChanged extends WorkoutEvent {
  const WorkoutSideFieldChanged(
    this.entryIdx,
    this.setIdx,
    this.side,
    this.field,
    this.value,
  );

  final int entryIdx;
  final int setIdx;
  final String side;
  final String field;
  final Object? value;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, side, field, value];
}

/// Dispatched when toggling the done state of a set row or unilateral side.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:863-945 toggle.
final class WorkoutSetToggled extends WorkoutEvent {
  const WorkoutSetToggled(
    this.entryIdx,
    this.setIdx, {
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final String? side;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, side];
}

/// Dispatched when picking or clearing an effort rating (RIR/RPE), concluding the set if not done.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:253-285 effortCell, 305-325 sideEffortCell.
final class WorkoutEffortPicked extends WorkoutEvent {
  const WorkoutEffortPicked(
    this.entryIdx,
    this.setIdx, {
    this.side,
    this.value,
  });

  final int entryIdx;
  final int setIdx;
  final String? side;
  final num? value;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, side, value];
}

/// Dispatched when the user taps the Start (play) button on a timed set row.
/// Drives [WorkoutTimerBloc] via `WorkoutWorkStarted`; on completion the bloc
/// auto-fires [WorkoutTimedSetLogged].
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:848-861 startTimed.
final class WorkoutTimedSetStarted extends WorkoutEvent {
  const WorkoutTimedSetStarted(this.entryIdx, this.setIdx);

  final int entryIdx;
  final int setIdx;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx];
}

/// Internal event fired by [WorkoutBloc] when [WorkoutTimerBloc] emits
/// [WorkoutTimerWorkDone]; logs the elapsed seconds and then runs the normal
/// toggle path (rest, superset, finish-check).
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:848-861 startTimed onDone callback.
final class WorkoutTimedSetLogged extends WorkoutEvent {
  const WorkoutTimedSetLogged(this.entryIdx, this.setIdx, this.elapsedSec);

  final int entryIdx;
  final int setIdx;
  final int elapsedSec;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, elapsedSec];
}

/// Dispatched to reconfigure an exercise's progression settings mid-session and rebuild rows.
/// Ported from `../openGym/frontend/src/views/Workout.jsx`:771-817 openProgressionSettings.
final class WorkoutProgressionConfigured extends WorkoutEvent {
  const WorkoutProgressionConfigured({
    required this.activeId,
    required this.entryIdx,
    required this.entryId,
    required this.entryCount,
    required this.cfg,
  });

  final String activeId;
  final int entryIdx;
  final String entryId;
  final int entryCount;
  final RoutineExercise cfg;

  @override
  List<Object?> get props => <Object?>[
        activeId,
        entryIdx,
        entryId,
        entryCount,
        cfg,
      ];
}
