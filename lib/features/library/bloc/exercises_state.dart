// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/catalogue/exercise_def.dart';

/// One-shot signals emitted by [ExercisesBloc] to notify listeners (e.g. toasts, sheet transitions).
sealed class ExercisesSignal extends Equatable {
  const ExercisesSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Generic user toast notification.
final class ExercisesSignalToast extends ExercisesSignal {
  const ExercisesSignalToast(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Request to show deletion confirmation dialog for a custom exercise.
final class ExercisesSignalConfirmDelete extends ExercisesSignal {
  const ExercisesSignalConfirmDelete(this.exercise);

  final ExerciseDef exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

/// Emitted after successfully creating or editing a custom exercise.
final class ExercisesSignalSaved extends ExercisesSignal {
  const ExercisesSignalSaved({
    required this.exercise,
    required this.message,
  });

  final ExerciseDef exercise;
  final String message;

  @override
  List<Object?> get props => <Object?>[exercise, message];
}

/// Emitted when an exercise has been added to a routine, optionally requesting navigation.
final class ExercisesSignalAddedToRoutine extends ExercisesSignal {
  const ExercisesSignalAddedToRoutine({
    this.routineId,
    required this.message,
  });

  final String? routineId;
  final String message;

  @override
  List<Object?> get props => <Object?>[routineId, message];
}

/// State for [ExercisesBloc] tracking one-shot signals with sequence numbers.
class ExercisesState extends Equatable {
  const ExercisesState({
    this.signal,
    this.seq = 0,
  });

  final ExercisesSignal? signal;
  final int seq;

  ExercisesState withSignal(ExercisesSignal sig) =>
      ExercisesState(signal: sig, seq: seq + 1);

  @override
  List<Object?> get props => <Object?>[signal, seq];
}
