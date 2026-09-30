// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/equipment.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/catalogue/exercise_search.dart';
import '../../../core/catalogue/favourites.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/muscle_view_js.dart';
import '../../../core/js/modules/muscles_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'muscles_event.dart';
import 'muscles_state.dart';

/// Screen-scoped BLoC managing MuscleExplorer filter pipeline and search results.
///
/// Mirrors `../openGym/frontend/src/components/MuscleExplorer.jsx` lines 18-44.
class MusclesBloc extends Bloc<MusclesEvent, MusclesState> {
  MusclesBloc({
    required this.gymState,
    required this.catalogue,
    required this.engine,
  }) : super(const MusclesInitial()) {
    on<MusclesEvent>(_onEvent, transformer: _sequential<MusclesEvent>());
    add(const MusclesStarted());
  }

  final GymStateCubit gymState;
  final ExerciseCatalogue catalogue;
  final JsEngineService engine;
  StreamSubscription<GymState>? _subscription;

  Map<String, Map<String, double>> _index = const <String, Map<String, double>>{};
  List<CustomExercise>? _cachedCustomEx;

  String? _selected;
  String _q = '';
  String _bp = '';
  String _eq = '';
  bool _showAll = false;
  int _shown = 40;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  void _onEvent(MusclesEvent event, Emitter<MusclesState> emit) {
    switch (event) {
      case MusclesStarted():
        _subscription?.cancel();
        _subscription = gymState.stream.listen((GymState s) {
          add(MusclesGymStateChanged(s));
        });
        emit(_computeState(gymState.state));
      case MusclesGymStateChanged(:final GymState state):
        emit(_computeState(state));
      case MusclesMuscleTapped(:final String slug):
        _selected = _selected == slug ? null : slug;
        _eq = '';
        _shown = 40;
        emit(_computeState(gymState.state));
      case MusclesQueryChanged(:final String query):
        _q = query;
        _shown = 40;
        emit(_computeState(gymState.state));
      case MusclesBodyPartSelected(:final String bodyPart):
        _bp = bodyPart;
        _eq = '';
        _shown = 40;
        emit(_computeState(gymState.state));
      case MusclesEquipmentSelected(:final String equipment):
        _eq = equipment;
        _shown = 40;
        emit(_computeState(gymState.state));
      case MusclesShowAllToggled():
        _showAll = !_showAll;
        _eq = '';
        _shown = 40;
        emit(_computeState(gymState.state));
      case MusclesShowMoreRequested():
        _shown += 40;
        emit(_computeState(gymState.state));
    }
  }

  void _ensureIndex(GymState s) {
    if (_index.isEmpty || !listEquals(_cachedCustomEx, s.customEx)) {
      _index = engine.muscleView.muscleIndex(s);
      _cachedCustomEx = s.customEx == null ? null : List<CustomExercise>.from(s.customEx!);
    }
  }

  MusclesReady _computeState(GymState s) {
    _ensureIndex(s);

    final EquipProfile? profile = activeProfile(s);
    final List<ExerciseDef> all = catalogue.allExercises(s);
    final List<ExerciseDef> catalog = (profile != null && !_showAll)
        ? all.where((ExerciseDef e) => exAvailable(s, e)).toList()
        : all;

    final List<String> muscleOrder = engine.muscles.muscles;
    final Map<String, String> muscleNames = engine.muscles.muscleName;

    final Map<String, int> counts = <String, int>{};
    for (final String m in muscleOrder) {
      counts[m] = catalog.where((ExerciseDef e) => (_index[e.id]?[m] ?? 0.0) != 0.0).length;
    }

    final List<ExerciseDef> targeted = _selected == null
        ? const <ExerciseDef>[]
        : catalog.where((ExerciseDef e) => (_index[e.id]?[_selected] ?? 0.0) != 0.0).toList();

    final List<ExerciseDef> bpFiltered = _bp.isEmpty
        ? targeted
        : targeted.where((ExerciseDef e) => e.bp == _bp).toList();

    final List<ExerciseDef> base = searchExercises(bpFiltered, _q);
    final List<String> eqOpts = catalogue.equipmentOf(base);
    final String eqOn = eqOpts.contains(_eq) ? _eq : '';

    final List<ExerciseDef> filtered = eqOn.isNotEmpty
        ? base.where((ExerciseDef e) => e.eq == eqOn).toList()
        : base;

    final List<ExerciseDef> results = sortFavouritesFirst(filtered, s);

    final int count = _shown < results.length ? _shown : results.length;
    final Set<String> primaryIds = <String>{};
    if (_selected != null) {
      for (int i = 0; i < count; i++) {
        final ExerciseDef ex = results[i];
        if ((_index[ex.id]?[_selected] ?? 0.0) == 1.0) {
          primaryIds.add(ex.id);
        }
      }
    }

    final Map<String, double> bestWeights = <String, double>{};
    for (int i = 0; i < count; i++) {
      final ExerciseDef ex = results[i];
      final double best = engine.history.bestWeightFor(s, ex.id);
      if (best > 0) {
        bestWeights[ex.id] = best;
      }
    }

    final Set<String> favSet = favIds(s).toSet();

    return MusclesReady(
      selected: _selected,
      q: _q,
      bp: _bp,
      eq: _eq,
      eqOn: eqOn,
      eqOpts: eqOpts,
      shown: _shown,
      showAll: _showAll,
      profile: profile,
      muscleOrder: muscleOrder,
      muscleNames: muscleNames,
      counts: counts,
      results: results,
      primaryIds: primaryIds,
      bestWeights: bestWeights,
      favIds: favSet,
      body: s.body,
    );
  }
}
