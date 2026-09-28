// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/catalogue/exercise_search.dart';
import '../../../core/catalogue/favourites.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';

/// State of the exercise picker search, filters and pagination.
class ExercisePickerState extends Equatable {
  const ExercisePickerState({
    this.q = '',
    this.bp = '',
    this.eq = '',
    this.shown = 40,
    this.results = const <ExerciseDef>[],
    this.usageMap = const <String, int>{},
    this.favCount = 0,
    this.equipmentOptions = const <String>[],
  });

  final String q;
  final String bp; // '' | '★' | '☆' | body part
  final String eq;
  final int shown;
  final List<ExerciseDef> results;
  final Map<String, int> usageMap;
  final int favCount;
  final List<String> equipmentOptions;

  ExercisePickerState copyWith({
    String? q,
    String? bp,
    String? eq,
    int? shown,
    List<ExerciseDef>? results,
    Map<String, int>? usageMap,
    int? favCount,
    List<String>? equipmentOptions,
  }) {
    return ExercisePickerState(
      q: q ?? this.q,
      bp: bp ?? this.bp,
      eq: eq ?? this.eq,
      shown: shown ?? this.shown,
      results: results ?? this.results,
      usageMap: usageMap ?? this.usageMap,
      favCount: favCount ?? this.favCount,
      equipmentOptions: equipmentOptions ?? this.equipmentOptions,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        q,
        bp,
        eq,
        shown,
        results,
        usageMap,
        favCount,
        equipmentOptions,
      ];
}

/// Sheet-scoped cubit managing search, filters and pagination for ExercisePicker.
/// Ported from ../openGym/frontend/src/sheets.jsx:907-1004.
class ExercisePickerCubit extends Cubit<ExercisePickerState> {
  ExercisePickerCubit({
    required GymStateCubit gymState,
    required ExerciseCatalogue catalogue,
  })  :
        // ignore: prefer_initializing_formals
        _gymState = gymState,
        // ignore: prefer_initializing_formals
        _catalogue = catalogue,
        super(const ExercisePickerState()) {
    _subscription = _gymState.stream.listen((GymState s) {
      emit(_computeState(
        gymState: s,
        query: state.q,
        bodyPart: state.bp,
        equipment: state.eq,
        shown: state.shown,
      ));
    });
    emit(_computeState(
      gymState: _gymState.state,
      query: state.q,
      bodyPart: state.bp,
      equipment: state.eq,
      shown: state.shown,
    ));
  }

  final GymStateCubit _gymState;
  final ExerciseCatalogue _catalogue;
  StreamSubscription<GymState>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  void queryChanged(String q) {
    emit(_computeState(
      gymState: _gymState.state,
      query: q,
      bodyPart: state.bp,
      equipment: state.eq,
      shown: 40,
    ));
  }

  void bodyPartSelected(String bp) {
    final String nextEq = bp.isEmpty ? '' : state.eq;
    emit(_computeState(
      gymState: _gymState.state,
      query: state.q,
      bodyPart: bp,
      equipment: nextEq,
      shown: 40,
    ));
  }

  void equipmentSelected(String eq) {
    emit(_computeState(
      gymState: _gymState.state,
      query: state.q,
      bodyPart: state.bp,
      equipment: eq,
      shown: 40,
    ));
  }

  void showMore() {
    emit(_computeState(
      gymState: _gymState.state,
      query: state.q,
      bodyPart: state.bp,
      equipment: state.eq,
      shown: state.shown + 40,
    ));
  }

  ExercisePickerState _computeState({
    required GymState gymState,
    required String query,
    required String bodyPart,
    required String equipment,
    required int shown,
  }) {
    // 1. Build usage map from routines and active workout
    final Map<String, int> usage = <String, int>{};
    for (final Routine r in gymState.routines ?? const <Routine>[]) {
      for (final RoutineExercise e in r.ex ?? const <RoutineExercise>[]) {
        if (e.id != null) {
          usage[e.id!] = (usage[e.id!] ?? 0) + 1;
        }
      }
    }
    if (gymState.active?.entries != null) {
      for (final WorkoutEntry e in gymState.active!.entries!) {
        if (e.id != null) {
          usage[e.id!] = (usage[e.id!] ?? 0) + 1;
        }
      }
    }

    final int favCount = favIds(gymState).length;
    final List<ExerciseDef> all = _catalogue.allExercises(gymState);

    // 2. Filter inScope for body part mode ('★' used, '☆' favourites, specific bp, or all)
    final List<ExerciseDef> inScope;
    if (bodyPart == '★') {
      inScope = all.where((ExerciseDef e) => usage.containsKey(e.id)).toList();
    } else if (bodyPart == '☆') {
      final Set<String> favs = favIds(gymState).toSet();
      inScope = all.where((ExerciseDef e) => favs.contains(e.id)).toList();
    } else if (bodyPart.isNotEmpty) {
      inScope = all.where((ExerciseDef e) => e.bp == bodyPart).toList();
    } else {
      inScope = all;
    }

    // 3. Typo-tolerant search
    final List<ExerciseDef> searched = searchExercises(inScope, query);

    // 4. Equipment options & filter
    final List<String> eqOpts = _catalogue.equipmentOf(searched);
    final String eqOn = eqOpts.contains(equipment) ? equipment : '';
    final List<ExerciseDef> finalFiltered = eqOn.isNotEmpty
        ? searched.where((ExerciseDef e) => e.eq == eqOn).toList()
        : searched;

    // 5. Sort favourites first
    final List<ExerciseDef> results = sortFavouritesFirst(finalFiltered, gymState);

    return ExercisePickerState(
      q: query,
      bp: bodyPart,
      eq: eqOn,
      shown: shown,
      results: results,
      usageMap: usage,
      favCount: favCount,
      equipmentOptions: eqOpts,
    );
  }
}
