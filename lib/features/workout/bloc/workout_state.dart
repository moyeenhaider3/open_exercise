// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/format/workout_controls.dart';
import '../../../core/js/models/phase3_models.dart';
import '../../../core/models/workout.dart';

/// One-shot signals emitted by [WorkoutBloc].
sealed class WorkoutSignal extends Equatable {
  const WorkoutSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Signal notifying UI that a workout session has started (triggering navigation to /workout).
final class WorkoutStartedSignal extends WorkoutSignal {
  const WorkoutStartedSignal();
}

/// Signal notifying UI that all sets in the session are finished (triggering workoutCompleteSheet).
final class WorkoutAllDoneSignal extends WorkoutSignal {
  const WorkoutAllDoneSignal();
}

/// Signal notifying UI to display a transient toast.
final class WorkoutToastSignal extends WorkoutSignal {
  const WorkoutToastSignal(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Signal requesting the UI to verify completion with the user (shows confirm dialogs).
final class WorkoutFinishCheckSignal extends WorkoutSignal {
  const WorkoutFinishCheckSignal({
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  @override
  List<Object?> get props => <Object?>[done, total];
}

/// Signal emitted after workout completion is successfully committed to history.
final class WorkoutFinishedSignal extends WorkoutSignal {
  const WorkoutFinishedSignal(this.result);

  final FinishResult result;

  @override
  List<Object?> get props => <Object?>[result];
}

/// Base sealed state for [WorkoutBloc].
sealed class WorkoutState extends Equatable {
  const WorkoutState({
    this.signal,
    this.seq = 0,
  });

  final WorkoutSignal? signal;
  final int seq;

  @override
  List<Object?> get props => <Object?>[signal, seq];
}

/// State when no workout session is active.
final class WorkoutNone extends WorkoutState {
  const WorkoutNone({
    super.signal,
    super.seq = 0,
  });

  WorkoutNone withSignal(WorkoutSignal sig) =>
      WorkoutNone(signal: sig, seq: seq + 1);
}

/// State when an active workout is in progress.
/// Derivations mirror `../openGym/frontend/src/views/Workout.jsx` lines 517-545.
final class WorkoutRunning extends WorkoutState {
  const WorkoutRunning({
    required this.active,
    required this.units,
    required this.cur,
    required this.currentUnit,
    required this.unitIdx,
    required this.view,
    required this.setsDone,
    required this.setsTotal,
    required this.wc,
    super.signal,
    super.seq = 0,
  });

  final Workout active;
  final List<List<int>> units;
  final int cur;
  final List<int> currentUnit;
  final int unitIdx;
  final String view;
  final int setsDone;
  final int setsTotal;
  final WorkoutControlsView wc;

  WorkoutRunning withSignal(WorkoutSignal sig) => WorkoutRunning(
        active: active,
        units: units,
        cur: cur,
        currentUnit: currentUnit,
        unitIdx: unitIdx,
        view: view,
        setsDone: setsDone,
        setsTotal: setsTotal,
        wc: wc,
        signal: sig,
        seq: seq + 1,
      );

  WorkoutRunning copyWith({
    Workout? active,
    List<List<int>>? units,
    int? cur,
    List<int>? currentUnit,
    int? unitIdx,
    String? view,
    int? setsDone,
    int? setsTotal,
    WorkoutControlsView? wc,
    WorkoutSignal? signal,
    int? seq,
  }) {
    return WorkoutRunning(
      active: active ?? this.active,
      units: units ?? this.units,
      cur: cur ?? this.cur,
      currentUnit: currentUnit ?? this.currentUnit,
      unitIdx: unitIdx ?? this.unitIdx,
      view: view ?? this.view,
      setsDone: setsDone ?? this.setsDone,
      setsTotal: setsTotal ?? this.setsTotal,
      wc: wc ?? this.wc,
      signal: signal ?? this.signal,
      seq: seq ?? this.seq,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        active,
        units,
        cur,
        currentUnit,
        unitIdx,
        view,
        setsDone,
        setsTotal,
        wc,
        signal,
        seq,
      ];
}
