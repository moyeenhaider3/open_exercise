// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// One-shot signals emitted by [WorkoutTimerBloc].
sealed class WorkoutTimerSignal extends Equatable {
  const WorkoutTimerSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Emitted when a rest countdown reaches zero (seenLive or not).
final class WorkoutTimerRestOver extends WorkoutTimerSignal {
  const WorkoutTimerRestOver();
}

/// Emitted when a work set completes (normally or via finishWorkEarly).
final class WorkoutTimerWorkDone extends WorkoutTimerSignal {
  const WorkoutTimerWorkDone({
    required this.entryIdx,
    required this.setIdx,
    required this.elapsedSec,
  });

  final int entryIdx;
  final int setIdx;
  final int elapsedSec;

  @override
  List<Object?> get props => <Object?>[entryIdx, setIdx, elapsedSec];
}

/// Base sealed state for [WorkoutTimerBloc].
///
/// Every subclass carries [flashId] (incremented on each flash to allow
/// diff-detection), [seq] (for signal detection), and [signal] (one-shot).
/// Mirrors the signal+seq pattern from [WorkoutState].
sealed class WorkoutTimerState extends Equatable {
  const WorkoutTimerState({
    required this.flashId,
    required this.seq,
    this.signal,
  });

  final int flashId;
  final int seq;
  final WorkoutTimerSignal? signal;

  @override
  List<Object?> get props => <Object?>[flashId, seq, signal];
}

/// No timer running.
final class WorkoutTimerIdle extends WorkoutTimerState {
  const WorkoutTimerIdle({
    super.flashId = 0,
    super.seq = 0,
    super.signal,
  });

  WorkoutTimerIdle withSignal(WorkoutTimerSignal sig) =>
      WorkoutTimerIdle(flashId: flashId, seq: seq + 1, signal: sig);

  WorkoutTimerIdle withFlash(int id) =>
      WorkoutTimerIdle(flashId: id, seq: seq, signal: signal);
}

/// Rest countdown is active.
final class WorkoutRestRunning extends WorkoutTimerState {
  const WorkoutRestRunning({
    required this.left,
    required this.total,
    required this.endsAtMs,
    required this.forIdx,
    required super.flashId,
    required super.seq,
    super.signal,
  });

  /// Seconds remaining (updated each tick).
  final int left;

  /// Original rest duration in seconds.
  final int total;

  /// Epoch ms when this rest ends (used for seenLive computation and scheduling).
  final int endsAtMs;

  /// Index of the workout entry that triggered this rest (nullable in JS, mapped to -1 here).
  final int? forIdx;

  WorkoutRestRunning copyWith({
    int? left,
    int? total,
    int? endsAtMs,
    int? forIdx,
    int? flashId,
    int? seq,
    WorkoutTimerSignal? signal,
  }) {
    return WorkoutRestRunning(
      left: left ?? this.left,
      total: total ?? this.total,
      endsAtMs: endsAtMs ?? this.endsAtMs,
      forIdx: forIdx ?? this.forIdx,
      flashId: flashId ?? this.flashId,
      seq: seq ?? this.seq,
      signal: signal ?? this.signal,
    );
  }

  @override
  List<Object?> get props => <Object?>[left, total, endsAtMs, forIdx, flashId, seq, signal];
}

/// Work/hold countdown is active.
final class WorkoutWorkRunning extends WorkoutTimerState {
  const WorkoutWorkRunning({
    required this.left,
    required this.total,
    required this.endsAtMs,
    required this.label,
    required this.entryIdx,
    required this.setIdx,
    required super.flashId,
    required super.seq,
    super.signal,
  });

  /// Seconds remaining.
  final int left;

  /// Original work duration in seconds.
  final int total;

  /// Epoch ms when this work set ends.
  final int endsAtMs;

  /// Display label for the exercise (may be empty).
  final String label;

  /// Entry index (to construct [WorkoutTimerWorkDone]).
  final int entryIdx;

  /// Set index (to construct [WorkoutTimerWorkDone]).
  final int setIdx;

  WorkoutWorkRunning copyWith({
    int? left,
    int? total,
    int? endsAtMs,
    String? label,
    int? entryIdx,
    int? setIdx,
    int? flashId,
    int? seq,
    WorkoutTimerSignal? signal,
  }) {
    return WorkoutWorkRunning(
      left: left ?? this.left,
      total: total ?? this.total,
      endsAtMs: endsAtMs ?? this.endsAtMs,
      label: label ?? this.label,
      entryIdx: entryIdx ?? this.entryIdx,
      setIdx: setIdx ?? this.setIdx,
      flashId: flashId ?? this.flashId,
      seq: seq ?? this.seq,
      signal: signal ?? this.signal,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[left, total, endsAtMs, label, entryIdx, setIdx, flashId, seq, signal];
}
