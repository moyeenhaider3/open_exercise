// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/phase31_models.dart';
import '../../../core/js/modules/effort_js.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/view_aggregates_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/ui_kit/heatmap.dart';
import 'stats_event.dart';
import 'stats_state.dart';

/// App-scoped BLoC managing Stats screen selections and derived data.
///
/// All domain aggregates and calculations delegate to [JsEngineService] (JS-04).
/// Selections (range, metric, effort window, exercise) are screen-local and not
/// persisted to [GymState].
/// Mirrors `../openGym/frontend/src/views/Stats.jsx`.
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
    required ExerciseCatalogue catalogue,
  })  : _gymState = gymState,
        _engine = engine,
        _catalogue = catalogue,
        super(
          _deriveState(
            gymState.state,
            90,
            null,
            'top',
            90,
            engine,
            catalogue,
          ),
        ) {
    on<StatsEvent>(_onEvent, transformer: _sequential<StatsEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(StatsGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  final ExerciseCatalogue _catalogue;
  StreamSubscription<GymState>? _subscription;

  int _range = 90;
  String? _selectedExerciseId;
  String _metric = 'top';
  int _effortWindow = 90;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(StatsEvent event, Emitter<StatsState> emit) async {
    switch (event) {
      case StatsGymStateChanged(:final GymState state):
        emit(
          _deriveState(
            state,
            _range,
            _selectedExerciseId,
            _metric,
            _effortWindow,
            _engine,
            _catalogue,
          ),
        );
      case StatsRangeChanged(:final int days):
        _range = days;
        emit(
          _deriveState(
            _gymState.state,
            _range,
            _selectedExerciseId,
            _metric,
            _effortWindow,
            _engine,
            _catalogue,
          ),
        );
      case StatsExerciseSelected(:final String id):
        _selectedExerciseId = id;
        emit(
          _deriveState(
            _gymState.state,
            _range,
            _selectedExerciseId,
            _metric,
            _effortWindow,
            _engine,
            _catalogue,
          ),
        );
      case StatsExerciseMetricChanged(:final String metric):
        _metric = metric;
        emit(
          _deriveState(
            _gymState.state,
            _range,
            _selectedExerciseId,
            _metric,
            _effortWindow,
            _engine,
            _catalogue,
          ),
        );
      case StatsEffortWindowChanged(:final int days):
        _effortWindow = days;
        emit(
          _deriveState(
            _gymState.state,
            _range,
            _selectedExerciseId,
            _metric,
            _effortWindow,
            _engine,
            _catalogue,
          ),
        );
    }
  }

  /// Projects [GymState] and current selections into [StatsReady].
  /// Mirrors `../openGym/frontend/src/views/Stats.jsx` lines 236-435.
  static StatsReady _deriveState(
    GymState s,
    int range,
    String? selectedExerciseId,
    String metric,
    int effortWindow,
    JsEngineService engine,
    ExerciseCatalogue catalogue,
  ) {
    final DateTime now = DateTime.now();
    final int nowMs = now.millisecondsSinceEpoch;
    final String today = todayIso();

    final StatsTiles tiles = engine.viewAgg.statsTiles(s, nowMs: nowMs, todayIso: today);
    final int streak = engine.history.streakWeeks(s);
    final BodyweightEntry? lastBw = engine.history.lastBW(s);

    final HeatmapAggregate heatmapAgg = engine.viewAgg.heatmapDays(s);
    final Map<String, HeatmapDayInfo> heatmap = heatmapAgg.days.map(
      (String k, HeatmapDay v) => MapEntry<String, HeatmapDayInfo>(
        k,
        HeatmapDayInfo(n: v.n, vol: v.vol, min: v.min, level: v.level),
      ),
    );

    final List<ChartPoint> bwPoints = engine.viewAgg.bodyweightPoints(s, range, nowMs);

    final bool hasEffort = engine.effort.hasEffort(s);
    final String kind = engine.effort.displayScale(s);
    final String hd = engine.effort.scaleName(kind);

    final EffortSummary? effortSummary =
        hasEffort ? engine.effort.effortSummary(s, effortWindow) : null;
    final List<EffortWeek>? effortWeeks =
        hasEffort ? engine.effort.effortWeeks(s, effortWindow) : null;
    final List<EffortBin>? effortHistogram =
        hasEffort ? engine.effort.effortHistogram(s, effortWindow) : null;

    final Map<String, String> names = <String, String>{};
    for (final Workout w in s.workouts ?? const <Workout>[]) {
      for (final WorkoutEntry e in w.entries ?? const <WorkoutEntry>[]) {
        final String? id = e.id;
        if (id == null || id.isEmpty || names.containsKey(id)) continue;
        final ExerciseDef lookupDef = catalogue.lookup(s, id);
        if (!lookupDef.missing && lookupDef.n.isNotEmpty) {
          names[id] = lookupDef.n;
        } else if (e.extra['name'] case final String name when name.isNotEmpty) {
          names[id] = name;
        } else {
          names[id] = id;
        }
      }
    }

    final ExerciseProgress progress =
        engine.viewAgg.exerciseProgress(s, selectedExerciseId, kind, names);

    final String effectiveMetric;
    if (progress.showEff && metric == 'effort') {
      effectiveMetric = 'effort';
    } else if (progress.showE1 && metric == 'e1rm') {
      effectiveMetric = 'e1rm';
    } else {
      effectiveMetric = 'top';
    }

    final String effortMode = engine.history.effortOf(s);
    final int hardRir = engine.effort.hardRir;

    return StatsReady(
      range: range,
      selectedExerciseId: selectedExerciseId,
      metric: metric,
      effectiveMetric: effectiveMetric,
      effortWindow: effortWindow,
      tiles: tiles,
      streak: streak,
      lastBw: lastBw,
      heatmap: heatmap,
      bwPoints: bwPoints,
      hasEffort: hasEffort,
      kind: kind,
      hd: hd,
      effortSummary: effortSummary,
      effortWeeks: effortWeeks,
      effortHistogram: effortHistogram,
      progress: progress,
      effortMode: effortMode,
      hardRir: hardRir,
      unit: s.unit ?? 'kg',
      targetWeight: s.targetW,
      workouts: s.workouts ?? const <Workout>[],
      weekStart: weekStartOf(s),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
