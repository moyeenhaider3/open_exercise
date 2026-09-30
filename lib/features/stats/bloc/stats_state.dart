// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/js/models/phase31_models.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/workout.dart';
import '../../../core/ui_kit/heatmap.dart';

/// State of [StatsBloc].
sealed class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Fully projected Stats state holding selections and all bridged derived views.
final class StatsReady extends StatsState {
  const StatsReady({
    required this.range,
    this.selectedExerciseId,
    required this.metric,
    required this.effectiveMetric,
    required this.effortWindow,
    required this.tiles,
    required this.streak,
    this.lastBw,
    required this.heatmap,
    required this.bwPoints,
    required this.hasEffort,
    required this.kind,
    required this.hd,
    this.effortSummary,
    this.effortWeeks,
    this.effortHistogram,
    required this.progress,
    required this.effortMode,
    required this.hardRir,
    required this.unit,
    this.targetWeight,
    required this.workouts,
    required this.weekStart,
  });

  /// Selected bodyweight chart range in days (0 = All, 30, 90, 365).
  final int range;

  /// Selected exercise ID (or null when using default).
  final String? selectedExerciseId;

  /// Selected exercise metric: 'top', 'e1rm', or 'effort'.
  final String metric;

  /// Effective metric after checking progress.showEff and progress.showE1.
  final String effectiveMetric;

  /// Selected effort stats window in days (0 = All, 30, 90, 365).
  final int effortWindow;

  /// Headline tiles (workouts total, monthW, bwDelta30).
  final StatsTiles tiles;

  /// Weekly streak count.
  final int streak;

  /// Most recent bodyweight entry.
  final BodyweightEntry? lastBw;

  /// 53-week activity heatmap aggregate per ISO date.
  final Map<String, HeatmapDayInfo> heatmap;

  /// Filtered bodyweight points for the line chart.
  final List<ChartPoint> bwPoints;

  /// Whether profile has any rated sets.
  final bool hasEffort;

  /// Display scale ('rir' or 'rpe').
  final String kind;

  /// Scale name ('RIR' or 'RPE').
  final String hd;

  /// Effort headline summary for [effortWindow].
  final EffortSummary? effortSummary;

  /// Weekly effort data points for [effortWindow].
  final List<EffortWeek>? effortWeeks;

  /// Effort distribution histogram bins for [effortWindow].
  final List<EffortBin>? effortHistogram;

  /// Full exercise progress data for selected exercise.
  final ExerciseProgress progress;

  /// Effort logging mode ('rir', 'rpe', 'both', or 'none').
  final String effortMode;

  /// Hard RIR threshold from effort config.
  final int hardRir;

  /// Weight unit ('kg' or 'lb').
  final String unit;

  /// Target bodyweight if set in settings.
  final num? targetWeight;

  /// All completed workouts from state.
  final List<Workout> workouts;

  /// User week start day (0 = Sunday, 1 = Monday).
  final int weekStart;

  @override
  List<Object?> get props => <Object?>[
        range,
        selectedExerciseId,
        metric,
        effectiveMetric,
        effortWindow,
        tiles,
        streak,
        lastBw,
        heatmap,
        bwPoints,
        hasEffort,
        kind,
        hd,
        effortSummary,
        effortWeeks,
        effortHistogram,
        progress,
        effortMode,
        hardRir,
        unit,
        targetWeight,
        workouts,
        weekStart,
      ];
}
