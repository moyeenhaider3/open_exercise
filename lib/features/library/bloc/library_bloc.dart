// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/equipment.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/catalogue/exercise_search.dart';
import '../../../core/catalogue/favourites.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'library_event.dart';
import 'library_state.dart';

/// Screen-scoped BLoC managing search, filters, pagination and best weights
/// for the Library exercise browse view.
///
/// Ports the filter pipeline from `../openGym/frontend/src/views/Library.jsx`.
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({
    required this._gymState,
    required this._catalogue,
    required this._engine,
  }) : super(const LibraryState()) {
    on<LibraryEvent>(_onEvent);
    add(const LibraryStarted());
  }

  final GymStateCubit _gymState;
  final ExerciseCatalogue _catalogue;
  final JsEngineService _engine;
  StreamSubscription<GymState>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  void _onEvent(LibraryEvent event, Emitter<LibraryState> emit) {
    switch (event) {
      case LibraryStarted():
        _onStarted(emit);
      case LibraryGymStateChanged(:final GymState state):
        _onGymStateChanged(state, emit);
      case LibraryQueryChanged(:final String query):
        _onQueryChanged(query, emit);
      case LibraryBodyPartSelected(:final String bodyPart):
        _onBodyPartSelected(bodyPart, emit);
      case LibraryEquipmentSelected(:final String equipment):
        _onEquipmentSelected(equipment, emit);
      case LibraryShowAllToggled():
        _onShowAllToggled(emit);
      case LibraryShowMoreRequested():
        _onShowMoreRequested(emit);
    }
  }

  void _onStarted(Emitter<LibraryState> emit) {
    _subscription?.cancel();
    _subscription = _gymState.stream.listen((GymState s) {
      add(LibraryGymStateChanged(s));
    });
    emit(_computeState(
      gymState: _gymState.state,
      query: state.query,
      bodyPart: state.bodyPart,
      equipment: state.equipment,
      showAll: state.showAll,
      shown: state.shown,
    ));
  }

  void _onGymStateChanged(GymState state, Emitter<LibraryState> emit) {
    emit(_computeState(
      gymState: state,
      query: this.state.query,
      bodyPart: this.state.bodyPart,
      equipment: this.state.equipment,
      showAll: this.state.showAll,
      shown: this.state.shown,
    ));
  }

  void _onQueryChanged(String query, Emitter<LibraryState> emit) {
    emit(_computeState(
      gymState: _gymState.state,
      query: query,
      bodyPart: state.bodyPart,
      equipment: state.equipment,
      showAll: state.showAll,
      shown: 40,
    ));
  }

  void _onBodyPartSelected(String bodyPart, Emitter<LibraryState> emit) {
    // If 'All' is selected (empty string), clear the equipment filter too (Library.jsx:54).
    final String nextEquipment = bodyPart.isEmpty ? '' : state.equipment;
    emit(_computeState(
      gymState: _gymState.state,
      query: state.query,
      bodyPart: bodyPart,
      equipment: nextEquipment,
      showAll: state.showAll,
      shown: 40,
    ));
  }

  void _onEquipmentSelected(String equipment, Emitter<LibraryState> emit) {
    emit(_computeState(
      gymState: _gymState.state,
      query: state.query,
      bodyPart: state.bodyPart,
      equipment: equipment,
      showAll: state.showAll,
      shown: 40,
    ));
  }

  void _onShowAllToggled(Emitter<LibraryState> emit) {
    emit(_computeState(
      gymState: _gymState.state,
      query: state.query,
      bodyPart: state.bodyPart,
      equipment: state.equipment,
      showAll: !state.showAll,
      shown: state.shown,
    ));
  }

  void _onShowMoreRequested(Emitter<LibraryState> emit) {
    final int nextShown = state.shown + 40;
    emit(_computeState(
      gymState: _gymState.state,
      query: state.query,
      bodyPart: state.bodyPart,
      equipment: state.equipment,
      showAll: state.showAll,
      shown: nextShown,
    ));
  }

  /// Exact filter and derivation pipeline from `../openGym/frontend/src/views/Library.jsx` lines 24-34.
  LibraryState _computeState({
    required GymState gymState,
    required String query,
    required String bodyPart,
    required String equipment,
    required bool showAll,
    required int shown,
  }) {
    final EquipProfile? profile = activeProfile(gymState);
    final List<ExerciseDef> all = _catalogue.allExercises(gymState);
    final List<ExerciseDef> bpFiltered = bodyPart.isEmpty
        ? all
        : all.where((ExerciseDef e) => e.bp == bodyPart).toList();
    final List<ExerciseDef> base = searchExercises(bpFiltered, query);
    final List<ExerciseDef> eqFiltered = (profile != null && !showAll)
        ? base.where((ExerciseDef e) => exAvailable(gymState, e)).toList()
        : base;
    final List<String> eqOpts = _catalogue.equipmentOf(eqFiltered);
    final String eqOn = eqOpts.contains(equipment) ? equipment : '';
    final List<ExerciseDef> finalFiltered = eqOn.isNotEmpty
        ? eqFiltered.where((ExerciseDef e) => e.eq == eqOn).toList()
        : eqFiltered;
    final List<ExerciseDef> f = sortFavouritesFirst(finalFiltered, gymState);

    // Call history.bestWeightFor via JS bridge only for the first `shown` rows to avoid 1300 invocations.
    final int count = shown < f.length ? shown : f.length;
    final Map<String, double> bestWeights = <String, double>{};
    for (int i = 0; i < count; i++) {
      final ExerciseDef ex = f[i];
      final double best = _engine.history.bestWeightFor(gymState, ex.id);
      if (best > 0) {
        bestWeights[ex.id] = best;
      }
    }

    final Set<String> favSet = favIds(gymState).toSet();
    final int total = _catalogue.catalogue.length;

    return LibraryState(
      query: query,
      bodyPart: bodyPart,
      equipment: equipment,
      showAll: showAll,
      shown: shown,
      results: f,
      eqOptions: eqOpts,
      eqOn: eqOn,
      profile: profile,
      bestWeights: bestWeights,
      favIds: favSet,
      total: total,
    );
  }
}
