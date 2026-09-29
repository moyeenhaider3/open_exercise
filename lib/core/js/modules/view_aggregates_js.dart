// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase31_models.dart';

/// Facade for openGym view-level aggregates transcribed in `view-aggregates-shim.js`.
///
/// Each method corresponds to one export in the shim and is called via the
/// `viewAgg.*` namespace in the bundled JS engine.
final class ViewAggregatesJs {
  const ViewAggregatesJs(this._engine);

  final JsEngineService _engine;

  // ---------------------------------------------------------------------------
  // Heatmap
  // ---------------------------------------------------------------------------

  /// Aggregates workouts by day and computes quartile thresholds for heatmap levels.
  /// Mirrors openGym `Heatmap.jsx` lines 11-19.
  HeatmapAggregate heatmapDays(GymState s) {
    final Object? res = _engine.call('viewAgg.heatmapDays', <Object?>[s.toJson()]);
    return HeatmapAggregate.fromJson(jsMap(res, 'viewAgg.heatmapDays'));
  }

  // ---------------------------------------------------------------------------
  // Stats tiles
  // ---------------------------------------------------------------------------

  /// Returns headline stat tile values: total workouts, month count, 30-day bw delta.
  /// Mirrors openGym `Stats.jsx` lines 297-302.
  ///
  /// [nowMs] and [todayIso] replace `Date.now()` / `todayISO()` for TZ stability.
  StatsTiles statsTiles(
    GymState s, {
    required int nowMs,
    required String todayIso,
  }) {
    final Object? res = _engine.call('viewAgg.statsTiles', <Object?>[
      s.toJson(),
      nowMs,
      todayIso,
    ]);
    return StatsTiles.fromJson(jsMap(res, 'viewAgg.statsTiles'));
  }

  // ---------------------------------------------------------------------------
  // Bodyweight chart
  // ---------------------------------------------------------------------------

  /// Returns bodyweight chart points filtered to a rolling window.
  /// Mirrors openGym `Stats.jsx` lines 297-298.
  ///
  /// [rangeDays] = 0 returns all history.
  List<ChartPoint> bodyweightPoints(GymState s, int rangeDays, int nowMs) {
    final Object? res = _engine.call('viewAgg.bodyweightPoints', <Object?>[
      s.toJson(),
      rangeDays,
      nowMs,
    ]);
    final List<Object?> list = jsList(res, 'viewAgg.bodyweightPoints');
    return list
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> m) => ChartPoint.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Exercise progress
  // ---------------------------------------------------------------------------

  /// Returns full exercise progress data for the Stats exercise card.
  /// Mirrors openGym `Stats.jsx` lines 305-435.
  ///
  /// [exId] = null uses the first entry in exHist.
  /// [kind] is 'rir' or 'rpe' (the display scale from [EffortJs.displayScale]).
  /// [names] is a `{ id → displayName }` map supplied by Dart (replaces i18n lookups).
  ExerciseProgress exerciseProgress(
    GymState s,
    String? exId,
    String kind,
    Map<String, String> names,
  ) {
    final Object? res = _engine.call('viewAgg.exerciseProgress', <Object?>[
      s.toJson(),
      exId ?? jsUndefined,
      kind,
      names,
    ]);
    return ExerciseProgress.fromJson(jsMap(res, 'viewAgg.exerciseProgress'));
  }

  // ---------------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------------

  /// Returns aggregate totals for a calendar month.
  /// Mirrors openGym `sheets.jsx` Calendar lines ~1773-1775.
  ///
  /// [year] is the full year (e.g. 2026), [month0] is 0-based (0 = January).
  CalendarMonthTotals calendarMonth(GymState s, int year, int month0) {
    final Object? res = _engine.call('viewAgg.calendarMonth', <Object?>[
      s.toJson(),
      year,
      month0,
    ]);
    return CalendarMonthTotals.fromJson(jsMap(res, 'viewAgg.calendarMonth'));
  }

  // ---------------------------------------------------------------------------
  // Workout detail groups
  // ---------------------------------------------------------------------------

  /// Groups a workout's entries by routine (rid) for the WorkoutDetail sheet.
  /// Mirrors openGym `sheets.jsx` WorkoutDetail lines ~1688-1720.
  WorkoutDetailGroups workoutDetailGroups(Workout w) {
    final Object? res = _engine.call('viewAgg.workoutDetailGroups', <Object?>[w.toJson()]);
    return WorkoutDetailGroups.fromJson(jsMap(res, 'viewAgg.workoutDetailGroups'));
  }

  // ---------------------------------------------------------------------------
  // Bodyweight goal
  // ---------------------------------------------------------------------------

  /// Returns goal proximity or null when no target is set.
  /// Mirrors openGym `Home.jsx` goal line and `GoalSheet` toast.
  BwGoal? bwGoal(GymState s) {
    final Object? res = _engine.call('viewAgg.bwGoal', <Object?>[s.toJson()]);
    if (res == null) return null;
    return BwGoal.fromJson(jsMap(res, 'viewAgg.bwGoal'));
  }

  // ---------------------------------------------------------------------------
  // Home view
  // ---------------------------------------------------------------------------

  /// Returns all derived numbers shown on the Home screen.
  /// Mirrors openGym `Home.jsx` lines 30-58.
  ///
  /// [todayIso] replaces `todayISO()` for TZ stability.
  HomeView homeView(GymState s, String todayIso) {
    final Object? res = _engine.call('viewAgg.homeView', <Object?>[
      s.toJson(),
      todayIso,
    ]);
    return HomeView.fromJson(jsMap(res, 'viewAgg.homeView'));
  }
}

extension ViewAggregatesJsAccess on JsEngineService {
  ViewAggregatesJs get viewAgg => ViewAggregatesJs(this);
}
