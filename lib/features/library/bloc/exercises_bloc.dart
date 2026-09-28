// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/catalogue/favourites.dart';
import '../../../core/format/format.dart';
import '../../../core/format/glyphs.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/muscles_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'exercises_event.dart';
import 'exercises_state.dart';

/// App-scoped BLoC managing exercise mutations (favourites, custom exercises,
/// adding to routines, bar weights, media sizes).
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
class ExercisesBloc extends Bloc<ExercisesEvent, ExercisesState> {
  ExercisesBloc({
    required this._gymState,
    required this._catalogue,
    required this._engine,
  }) : super(const ExercisesState()) {
    on<ExercisesEvent>(_onEvent, transformer: _sequential<ExercisesEvent>());
  }

  final GymStateCubit _gymState;
  final ExerciseCatalogue _catalogue;
  final JsEngineService _engine;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(ExercisesEvent event, Emitter<ExercisesState> emit) async {
    switch (event) {
      case ExerciseFavouriteToggled(:final String exerciseId):
        await _onFavouriteToggled(exerciseId, emit);
      case CustomExerciseSaved():
        await _onCustomExerciseSaved(event, emit);
      case CustomExerciseDeleteRequested(:final ExerciseDef exercise):
        _onCustomExerciseDeleteRequested(exercise, emit);
      case CustomExerciseDeleted(:final ExerciseDef exercise):
        await _onCustomExerciseDeleted(exercise, emit);
      case ExerciseAddedToRoutine():
        await _onExerciseAddedToRoutine(event, emit);
      case ExerciseBarWeightChanged(:final String exerciseId, :final num? weight):
        await _onBarWeightChanged(exerciseId, weight);
      case ExerciseNoBarChanged(:final String exerciseId, :final bool noBar):
        await _onNoBarChanged(exerciseId, noBar);
      case MediaSizeToggled():
        await _onMediaSizeToggled();
    }
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:658-668 flipFav.
  Future<void> _onFavouriteToggled(String exerciseId, Emitter<ExercisesState> emit) async {
    bool on = false;
    await _gymState.mutate((GymState s) {
      final (GymState next, bool isFavNow) = toggleFav(s, exerciseId);
      on = isFavNow;
      return next;
    });
    emit(state.withSignal(
      ExercisesSignalToast(on ? t('Added to favourites') : t('Removed from favourites')),
    ));
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:790-880 CustomExForm save.
  Future<void> _onCustomExerciseSaved(CustomExerciseSaved event, Emitter<ExercisesState> emit) async {
    final String name = event.name.trim();
    if (name.isEmpty) {
      emit(state.withSignal(ExercisesSignalToast(t('Give it a name'))));
      return;
    }
    if (event.bodyPart.isEmpty) {
      emit(state.withSignal(ExercisesSignalToast(t('Pick a body part'))));
      return;
    }
    if (event.equipment.isEmpty) {
      emit(state.withSignal(ExercisesSignalToast(t('Pick equipment'))));
      return;
    }

    final List<ExerciseDef> all = _catalogue.allExercises(_gymState.state);
    final ExerciseDef? dup = all.firstWhereOrNull(
      (ExerciseDef e) =>
          e.n.toLowerCase() == name.toLowerCase() && e.id != event.existingId,
    );
    if (dup != null) {
      emit(state.withSignal(ExercisesSignalToast(t('“{0}” already exists', <Object?>[dup.n]))));
      return;
    }

    final String desc = event.desc.trim();
    final String truncatedDesc = desc.length > 1000 ? desc.substring(0, 1000) : desc;

    // Stored in the map's order, not the order the chips were tapped in.
    final List<String> prim = event.bodyPart == 'cardio'
        ? const <String>['cardiovascular system']
        : _engine.muscles.inMuscleOrder(event.primaries);
    final List<String> sm = _engine.muscles.inMuscleOrder(
      event.secondaries.where((String m) => !prim.contains(m)).toList(),
    );
    final List<String> groups = <String>[...prim, ...sm];

    final ExerciseDef? existingDef =
        event.existingId != null ? _catalogue.byId(event.existingId!) : null;
    final String existingTg = existingDef?.tg ?? '';
    final String tg;
    if (existingDef != null && prim.contains(existingTg)) {
      tg = existingTg;
    } else {
      final String? foundTap =
          event.primaryTaps.firstWhereOrNull((String m) => prim.contains(m));
      tg = foundTap ?? (prim.isNotEmpty ? prim[0] : '');
    }

    final String id = event.existingId ?? 'c${uid()}';
    final bool isEdit = event.existingId != null;

    await _gymState.mutate((GymState s) {
      final List<CustomExercise> currentCustoms =
          List<CustomExercise>.from(s.customEx ?? const <CustomExercise>[]);
      final Map<String, Object?> exerciseMap = <String, Object?>{
        'id': id,
        'n': name,
        'bp': event.bodyPart,
        'desc': truncatedDesc,
        'tg': tg,
        'sm': sm,
        'muscleGroups': groups,
        'primaries': prim,
        'secondaries': sm,
        'eq': event.equipment,
        'custom': true,
      };

      if (isEdit) {
        final int idx = currentCustoms.indexWhere((CustomExercise c) => c.id == id);
        if (idx != -1) {
          final CustomExercise updated = CustomExercise(
            id: id,
            name: name,
            extra: <String, Object?>{
              ...currentCustoms[idx].extra,
              ...exerciseMap,
            },
          );
          currentCustoms[idx] = updated;
        }
      } else {
        final CustomExercise created = CustomExercise(
          id: id,
          name: name,
          extra: exerciseMap,
        );
        currentCustoms.add(created);
      }
      return s.copyWith(customEx: currentCustoms);
    });

    final ExerciseDef savedDef = ExerciseDef(
      id: id,
      n: name,
      bp: event.bodyPart,
      eq: event.equipment,
      tg: tg,
      sm: sm,
      desc: truncatedDesc,
      primaries: prim,
      secondaries: sm,
      custom: true,
    );

    emit(state.withSignal(ExercisesSignalSaved(
      exercise: savedDef,
      message: isEdit ? t('Saved') : t('“{0}” created', <Object?>[name]),
    )));
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:881-884 deleteCustomEx.
  void _onCustomExerciseDeleteRequested(ExerciseDef exercise, Emitter<ExercisesState> emit) {
    final GymState st = _gymState.state;
    final List<WorkoutEntry>? activeEntries = st.active?.entries;
    if (activeEntries != null && activeEntries.any((WorkoutEntry e) => e.id == exercise.id)) {
      emit(state.withSignal(ExercisesSignalToast(t('Finish your current workout first'))));
      return;
    }
    emit(state.withSignal(ExercisesSignalConfirmDelete(exercise)));
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:885-910.
  Future<void> _onCustomExerciseDeleted(ExerciseDef exercise, Emitter<ExercisesState> emit) async {
    await _gymState.mutate((GymState s) {
      final Map<String, Object?>? snapshot =
          _engine.muscles.exerciseMuscleSnapshot(exercise.toJson());

      // Keep display and muscle metadata in history before the custom catalogue row disappears.
      final List<Workout> nextWorkouts = (s.workouts ?? const <Workout>[]).map((Workout w) {
        bool changed = false;
        final List<WorkoutEntry> nextEntries = (w.entries ?? const <WorkoutEntry>[]).map((WorkoutEntry e) {
          if (e.id != exercise.id) return e;
          changed = true;
          final Map<String, Object?> nextExtra = Map<String, Object?>.from(e.extra);
          nextExtra['n'] = exercise.n;
          if (e.extra['muscleSnapshot'] == null && snapshot != null) {
            nextExtra['muscleSnapshot'] = snapshot;
          }
          return e.copyWith(extra: nextExtra);
        }).toList();
        return changed ? w.copyWith(entries: nextEntries) : w;
      }).toList();

      final List<CustomExercise> nextCustomEx =
          (s.customEx ?? const <CustomExercise>[]).where((CustomExercise x) => x.id != exercise.id).toList();

      final List<Routine> nextRoutines = (s.routines ?? const <Routine>[]).map((Routine r) {
        final List<RoutineExercise> filteredEx =
            (r.ex ?? const <RoutineExercise>[]).where((RoutineExercise re) => re.id != exercise.id).toList();
        final List<RoutineExercise> cleanedEx = _engine.history.cleanupSg(filteredEx);
        return r.copyWith(ex: cleanedEx);
      }).toList();

      final Map<String, num> nextExWeights =
          Map<String, num>.from(s.exWeights ?? const <String, num>{});
      nextExWeights.remove(exercise.id);

      final List<String> nextFavEx =
          (s.favEx ?? const <String>[]).where((String id) => id != exercise.id).toList();

      return s.copyWith(
        workouts: nextWorkouts,
        customEx: nextCustomEx,
        routines: nextRoutines,
        exWeights: nextExWeights,
        favEx: nextFavEx,
      );
    });

    emit(state.withSignal(ExercisesSignalToast(t('Exercise deleted'))));
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:755-785 AddToRoutine commit.
  Future<void> _onExerciseAddedToRoutine(ExerciseAddedToRoutine event, Emitter<ExercisesState> emit) async {
    final bool isNew = event.routineId == null || event.routineId == '_new';
    String? newRoutineId;
    String routineName = '';

    await _gymState.mutate((GymState s) {
      final List<Routine> routines = List<Routine>.from(s.routines ?? const <Routine>[]);
      if (isNew) {
        final String rid = uid();
        newRoutineId = rid;
        routineName = t('New routine');
        final Routine r = Routine(
          id: rid,
          name: routineName,
          emoji: kDefaultGlyph,
          ex: <RoutineExercise>[event.config],
        );
        routines.add(r);
      } else {
        final int idx = routines.indexWhere((Routine r) => r.id == event.routineId);
        if (idx != -1) {
          final Routine target = routines[idx];
          routineName = target.name ?? t('routine');
          final List<RoutineExercise> nextEx = <RoutineExercise>[
            ...(target.ex ?? const <RoutineExercise>[]),
            event.config,
          ];
          routines[idx] = target.copyWith(ex: nextEx);
        }
      }
      return s.copyWith(routines: routines);
    });

    emit(state.withSignal(ExercisesSignalAddedToRoutine(
      routineId: newRoutineId,
      message: t('“{0}” added to {1}', <Object?>[capWords(event.exercise.n), routineName]),
    )));
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:589 setBar.
  // Input normalization (Math.round(v * 100) / 100), not domain math.
  Future<void> _onBarWeightChanged(String exerciseId, num? weight) async {
    final double raw = weight != null ? (weight * 100).round() / 100.0 : 0.0;
    final double n = raw > 0 ? raw : 0.0;

    await _gymState.mutate((GymState s) {
      final Map<String, num> barWeights =
          Map<String, num>.from(s.barWeights ?? const <String, num>{});
      if (n > 0) {
        barWeights[exerciseId] = n;
      } else {
        barWeights.remove(exerciseId);
      }
      return s.copyWith(barWeights: barWeights);
    });
  }

  /// Ported from `../openGym/frontend/src/sheets.jsx`:594 setNoBar.
  Future<void> _onNoBarChanged(String exerciseId, bool noBar) async {
    await _gymState.mutate((GymState s) {
      final Map<String, num> barWeights =
          Map<String, num>.from(s.barWeights ?? const <String, num>{});
      if (noBar) {
        barWeights[exerciseId] = 0;
      } else {
        barWeights.remove(exerciseId);
      }
      return s.copyWith(barWeights: barWeights);
    });
  }

  /// Ported from `../openGym/frontend/src/components/Media.jsx`:26 toggleSize.
  Future<void> _onMediaSizeToggled() async {
    await _gymState.mutate((GymState s) {
      final bool mini = s.gifSize == 'mini';
      return s.copyWith(gifSize: mini ? 'full' : 'mini');
    });
  }
}
