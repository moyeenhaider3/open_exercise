// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Events for [WorkoutTimerBloc]: port of the timer + work slice of
/// ../openGym/frontend/src/store/useUI.js (lines 90-203) and
/// ../openGym/frontend/src/views/Workout.jsx (lines 495-510, 668-690).
sealed class WorkoutTimerEvent extends Equatable {
  const WorkoutTimerEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Starts a rest countdown.
/// Ports useUI.js startRest(sec, forIdx) — lines 107-113.
final class WorkoutRestStarted extends WorkoutTimerEvent {
  const WorkoutRestStarted({required this.sec, this.forIdx});

  final int sec;
  final int? forIdx;

  @override
  List<Object?> get props => <Object?>[sec, forIdx];
}

/// Adjusts rest time by [sec] seconds (negative to subtract).
/// Ports useUI.js addRest(sec) — lines 143-151.
final class WorkoutRestAdded extends WorkoutTimerEvent {
  const WorkoutRestAdded(this.sec);

  final int sec;

  @override
  List<Object?> get props => <Object?>[sec];
}

/// Shifts the rest owner index when an exercise is moved.
/// Ports useUI.js shiftRestOwner(at, delta) — lines 153-157.
final class WorkoutRestOwnerShifted extends WorkoutTimerEvent {
  const WorkoutRestOwnerShifted({required this.at, required this.delta});

  final int at;
  final int delta;

  @override
  List<Object?> get props => <Object?>[at, delta];
}

/// Remaps the rest owner index after a unit move (uses the moved indices array).
/// Ports Workout.jsx moveUnitAt remapping — lines 671-686.
final class WorkoutRestOwnerRemapped extends WorkoutTimerEvent {
  const WorkoutRestOwnerRemapped(this.indices);

  final List<int> indices;

  @override
  List<Object?> get props => <Object?>[indices];
}

/// Stops rest if it belongs to a removed exercise, else shifts owner.
/// Ports Workout.jsx removeActiveExercise — lines 495-510.
final class WorkoutRestExerciseRemoved extends WorkoutTimerEvent {
  const WorkoutRestExerciseRemoved(this.idx);

  final int idx;

  @override
  List<Object?> get props => <Object?>[idx];
}

/// Cancels the active rest countdown (Skip).
/// Ports useUI.js stopRest() — lines 159-165.
final class WorkoutRestStopped extends WorkoutTimerEvent {
  const WorkoutRestStopped();
}

/// Starts a work/hold countdown for a timed set.
/// Ports useUI.js startWork(sec, label, onDone) — lines 167-185.
final class WorkoutWorkStarted extends WorkoutTimerEvent {
  const WorkoutWorkStarted({
    required this.sec,
    required this.label,
    required this.entryIdx,
    required this.setIdx,
  });

  final num sec;
  final String label;
  final int entryIdx;
  final int setIdx;

  @override
  List<Object?> get props => <Object?>[sec, label, entryIdx, setIdx];
}

/// Finishes a work set early, logging actual elapsed time.
/// Ports useUI.js finishWorkEarly() — lines 187-192.
final class WorkoutWorkFinishedEarly extends WorkoutTimerEvent {
  const WorkoutWorkFinishedEarly();
}

/// Cancels the active work countdown (Cancel).
/// Ports useUI.js stopWork() — lines 194-198.
final class WorkoutWorkStopped extends WorkoutTimerEvent {
  const WorkoutWorkStopped();
}

/// Internal 1-second tick added by the periodic Timer.
/// Ports useUI.js timerTick — lines 118-142.
final class WorkoutTimerTicked extends WorkoutTimerEvent {
  const WorkoutTimerTicked();
}

/// App went hidden; cancel ticker, schedule notification if rest is running.
/// Ports useUI.js visibilitychange — lines 96-106.
final class WorkoutTimerAppHidden extends WorkoutTimerEvent {
  const WorkoutTimerAppHidden();
}

/// App returned to foreground; cancel notification, restart ticker and fire one tick.
/// Ports useUI.js visibilitychange — lines 96-106.
final class WorkoutTimerAppShown extends WorkoutTimerEvent {
  const WorkoutTimerAppShown();
}
