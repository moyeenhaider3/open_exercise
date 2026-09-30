// SPDX-License-Identifier: AGPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'history_event.dart';
import 'history_state.dart';

/// App-scoped BLoC managing workout note edits and workout deletions.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Mirrors `../openGym/frontend/src/sheets.jsx` saveNote and deleteWorkout.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        _engine = engine,
        super(const HistoryInitial()) {
    on<HistoryEvent>(_onEvent, transformer: _sequential<HistoryEvent>());
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(HistoryEvent event, Emitter<HistoryState> emit) async {
    switch (event) {
      case HistoryWorkoutNoteSaved(:final String workoutId, :final String text):
        await _onWorkoutNoteSaved(workoutId, text);
      case HistoryWorkoutDeleted(:final String workoutId):
        await _onWorkoutDeleted(workoutId);
    }
  }

  /// Saves or removes a workout note.
  /// Ported from `../openGym/frontend/src/sheets.jsx` lines 1666-1690.
  Future<void> _onWorkoutNoteSaved(String workoutId, String text) async {
    await _gymState.mutate((GymState s) {
      final List<Workout> workouts = s.workouts ?? const <Workout>[];
      final int idx = workouts.indexWhere((Workout w) => w.id == workoutId);
      if (idx == -1) return s; // Workout was deleted or not found.

      final int maxLen = _engine.history.noteMax;
      final String trimmed = text.trim();
      final String capped = trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
      final Workout target = workouts[idx];

      final Workout updated = capped.isNotEmpty
          ? target.withExtraFields(<String, Object?>{'note': capped})
          : target.withExtraFields(const <String, Object?>{}, remove: const <String>['note']);

      final List<Workout> next = List<Workout>.from(workouts);
      next[idx] = updated;
      return s.copyWith(workouts: next);
    });
  }

  /// Filters out a workout by ID.
  /// Ported from `../openGym/frontend/src/sheets.jsx` lines 1735-1740.
  Future<void> _onWorkoutDeleted(String workoutId) async {
    await _gymState.mutate((GymState s) {
      final List<Workout> workouts = s.workouts ?? const <Workout>[];
      final List<Workout> next =
          workouts.where((Workout w) => w.id != workoutId).toList();
      return s.copyWith(workouts: next);
    });
  }
}
