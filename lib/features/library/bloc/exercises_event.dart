// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/catalogue/exercise_def.dart';
import '../../../core/models/routine.dart';

/// Events for [ExercisesBloc] app-scoped mutations.
sealed class ExercisesEvent extends Equatable {
  const ExercisesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Dispatched when toggling the favourite status of an exercise.
/// Ported from `../openGym/frontend/src/sheets.jsx`:658-668 flipFav.
final class ExerciseFavouriteToggled extends ExercisesEvent {
  const ExerciseFavouriteToggled(this.exerciseId);

  final String exerciseId;

  @override
  List<Object?> get props => <Object?>[exerciseId];
}

/// Dispatched when saving a created or edited custom exercise.
/// Ported from `../openGym/frontend/src/sheets.jsx`:790-880 CustomExForm save.
final class CustomExerciseSaved extends ExercisesEvent {
  const CustomExerciseSaved({
    this.existingId,
    required this.name,
    required this.bodyPart,
    required this.desc,
    required this.equipment,
    required this.primaries,
    required this.secondaries,
    this.primaryTaps = const <String>[],
  });

  final String? existingId;
  final String name;
  final String bodyPart;
  final String desc;
  final String equipment;
  final List<String> primaries;
  final List<String> secondaries;
  final List<String> primaryTaps;

  @override
  List<Object?> get props => <Object?>[
        existingId,
        name,
        bodyPart,
        desc,
        equipment,
        primaries,
        secondaries,
        primaryTaps,
      ];
}

/// Dispatched when the user requests to delete a custom exercise.
/// Checks whether an active workout contains this exercise before confirming.
/// Ported from `../openGym/frontend/src/sheets.jsx`:881-884 deleteCustomEx.
final class CustomExerciseDeleteRequested extends ExercisesEvent {
  const CustomExerciseDeleteRequested(this.exercise);

  final ExerciseDef exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

/// Dispatched when deletion of a custom exercise is confirmed.
/// Ported from `../openGym/frontend/src/sheets.jsx`:885-910.
final class CustomExerciseDeleted extends ExercisesEvent {
  const CustomExerciseDeleted(this.exercise);

  final ExerciseDef exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

/// Dispatched when adding an exercise to an existing routine or creating a new routine.
/// Ported from `../openGym/frontend/src/sheets.jsx`:755-785 AddToRoutine commit.
final class ExerciseAddedToRoutine extends ExercisesEvent {
  const ExerciseAddedToRoutine({
    required this.exercise,
    this.routineId,
    required this.config,
  });

  final ExerciseDef exercise;
  final String? routineId;
  final RoutineExercise config;

  @override
  List<Object?> get props => <Object?>[exercise, routineId, config];
}

/// Dispatched when setting an explicit bar weight override.
/// Ported from `../openGym/frontend/src/sheets.jsx`:589 setBar.
final class ExerciseBarWeightChanged extends ExercisesEvent {
  const ExerciseBarWeightChanged(this.exerciseId, this.weight);

  final String exerciseId;
  final num? weight;

  @override
  List<Object?> get props => <Object?>[exerciseId, weight];
}

/// Dispatched when toggling the "no bar" setting for an exercise.
/// Ported from `../openGym/frontend/src/sheets.jsx`:594 setNoBar.
final class ExerciseNoBarChanged extends ExercisesEvent {
  const ExerciseNoBarChanged(this.exerciseId, this.noBar);

  final String exerciseId;
  final bool noBar;

  @override
  List<Object?> get props => <Object?>[exerciseId, noBar];
}

/// Dispatched when toggling animation media display size (mini vs full).
/// Ported from `../openGym/frontend/src/components/Media.jsx`:26 toggleSize.
final class MediaSizeToggled extends ExercisesEvent {
  const MediaSizeToggled();
}
