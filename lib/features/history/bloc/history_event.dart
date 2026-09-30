// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Sealed base class for all events handled by [HistoryBloc].
sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Dispatched when the user saves or flushes a session note on a workout.
/// Ported from `../openGym/frontend/src/sheets.jsx` WorkoutDetail saveNote.
final class HistoryWorkoutNoteSaved extends HistoryEvent {
  const HistoryWorkoutNoteSaved(this.workoutId, this.text);

  final String workoutId;
  final String text;

  @override
  List<Object?> get props => <Object?>[workoutId, text];
}

/// Dispatched when the user confirms deleting a workout.
/// Ported from `../openGym/frontend/src/sheets.jsx` WorkoutDetail delete.
final class HistoryWorkoutDeleted extends HistoryEvent {
  const HistoryWorkoutDeleted(this.workoutId);

  final String workoutId;

  @override
  List<Object?> get props => <Object?>[workoutId];
}
