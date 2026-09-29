// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/set_entry.dart';
import '../../models/routine.dart';

// ---------------------------------------------------------------------------
// Effort models
// ---------------------------------------------------------------------------

/// Headline effort statistics for a window (effortSummary).
class EffortSummary extends Equatable {
  const EffortSummary({
    required this.done,
    required this.rated,
    required this.hard,
    this.avg,
    this.hardPct,
  });

  factory EffortSummary.fromJson(Map<String, Object?> json) {
    return EffortSummary(
      done: (json['done'] as num?)?.toInt() ?? 0,
      rated: (json['rated'] as num?)?.toInt() ?? 0,
      hard: (json['hard'] as num?)?.toInt() ?? 0,
      avg: json['avg'] as num?,
      hardPct: json['hardPct'] as num?,
    );
  }

  final int done;
  final int rated;
  final int hard;
  final num? avg;
  final num? hardPct;

  Map<String, Object?> toJson() => <String, Object?>{
        'done': done,
        'rated': rated,
        'hard': hard,
        'avg': avg,
        'hardPct': hardPct,
      };

  @override
  List<Object?> get props => <Object?>[done, rated, hard, avg, hardPct];
}

/// Per-week effort summary entry (effortWeeks).
class EffortWeek extends Equatable {
  const EffortWeek({
    required this.t,
    required this.rir,
    required this.n,
    required this.sets,
  });

  factory EffortWeek.fromJson(Map<String, Object?> json) {
    return EffortWeek(
      t: (json['t'] as num?)?.toInt() ?? 0,
      rir: (json['rir'] as num?)?.toDouble() ?? 0.0,
      n: (json['n'] as num?)?.toInt() ?? 0,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
    );
  }

  final int t;
  final double rir;
  final int n;
  final int sets;

  Map<String, Object?> toJson() => <String, Object?>{
        't': t,
        'rir': rir,
        'n': n,
        'sets': sets,
      };

  @override
  List<Object?> get props => <Object?>[t, rir, n, sets];
}

/// Histogram bin for the effort distribution (effortHistogram).
class EffortBin extends Equatable {
  const EffortBin({
    required this.rir,
    required this.tail,
    required this.n,
    required this.pct,
  });

  factory EffortBin.fromJson(Map<String, Object?> json) {
    return EffortBin(
      rir: (json['rir'] as num?)?.toInt() ?? 0,
      tail: json['tail'] == true,
      n: (json['n'] as num?)?.toInt() ?? 0,
      pct: (json['pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int rir;
  final bool tail;
  final int n;
  final double pct;

  Map<String, Object?> toJson() => <String, Object?>{
        'rir': rir,
        'tail': tail,
        'n': n,
        'pct': pct,
      };

  @override
  List<Object?> get props => <Object?>[rir, tail, n, pct];
}

// ---------------------------------------------------------------------------
// Heatmap models
// ---------------------------------------------------------------------------

/// Per-day aggregate for the workout heatmap.
class HeatmapDay extends Equatable {
  const HeatmapDay({
    required this.n,
    required this.vol,
    required this.min,
    required this.level,
  });

  factory HeatmapDay.fromJson(Map<String, Object?> json) {
    return HeatmapDay(
      n: (json['n'] as num?)?.toInt() ?? 0,
      vol: (json['vol'] as num?) ?? 0,
      min: (json['min'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }

  final int n;
  final num vol;
  final int min;
  final int level;

  Map<String, Object?> toJson() => <String, Object?>{
        'n': n,
        'vol': vol,
        'min': min,
        'level': level,
      };

  @override
  List<Object?> get props => <Object?>[n, vol, min, level];
}

/// Full heatmap aggregate including quartile thresholds.
class HeatmapAggregate extends Equatable {
  const HeatmapAggregate({
    required this.days,
    required this.t1,
    required this.t2,
    required this.t3,
  });

  factory HeatmapAggregate.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> rawDays =
        (json['days'] as Map<Object?, Object?>?)?.cast<String, Object?>() ?? <String, Object?>{};
    final Map<String, HeatmapDay> days = rawDays.map(
      (String k, Object? v) => MapEntry<String, HeatmapDay>(
        k,
        HeatmapDay.fromJson((v as Map<Object?, Object?>).cast<String, Object?>()),
      ),
    );
    return HeatmapAggregate(
      days: days,
      t1: (json['t1'] as num?) ?? 0,
      t2: (json['t2'] as num?) ?? 0,
      t3: (json['t3'] as num?) ?? 0,
    );
  }

  final Map<String, HeatmapDay> days;
  final num t1;
  final num t2;
  final num t3;

  Map<String, Object?> toJson() => <String, Object?>{
        'days': days.map((String k, HeatmapDay v) => MapEntry<String, Object?>(k, v.toJson())),
        't1': t1,
        't2': t2,
        't3': t3,
      };

  @override
  List<Object?> get props => <Object?>[days, t1, t2, t3];
}

// ---------------------------------------------------------------------------
// Stats models
// ---------------------------------------------------------------------------

/// Stats tile headline values.
class StatsTiles extends Equatable {
  const StatsTiles({
    required this.workouts,
    required this.monthW,
    this.bwDelta30,
  });

  factory StatsTiles.fromJson(Map<String, Object?> json) {
    return StatsTiles(
      workouts: (json['workouts'] as num?)?.toInt() ?? 0,
      monthW: (json['monthW'] as num?)?.toInt() ?? 0,
      bwDelta30: json['bwDelta30'] as num?,
    );
  }

  final int workouts;
  final int monthW;
  final num? bwDelta30;

  Map<String, Object?> toJson() => <String, Object?>{
        'workouts': workouts,
        'monthW': monthW,
        'bwDelta30': bwDelta30,
      };

  @override
  List<Object?> get props => <Object?>[workouts, monthW, bwDelta30];
}

/// Single point on a chart series (bodyweight, exercise progress, effort, 1RM).
class ChartPoint extends Equatable {
  const ChartPoint({
    required this.t,
    required this.y,
    this.d,
    this.m,
    this.rirScale,
  });

  factory ChartPoint.fromJson(Map<String, Object?> json) {
    return ChartPoint(
      t: (json['t'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?) ?? 0,
      d: json['d'] as String?,
      m: json['m'] as num?,
      rirScale: json['rirScale'] as num?,
    );
  }

  final int t;
  final num y;
  final String? d;
  final num? m;
  final num? rirScale;

  Map<String, Object?> toJson() => <String, Object?>{
        't': t,
        'y': y,
        if (d != null) 'd': d,
        if (m != null) 'm': m,
        if (rirScale != null) 'rirScale': rirScale,
      };

  @override
  List<Object?> get props => <Object?>[t, y, d, m, rirScale];
}

/// Exercise picker option from the exHist list.
class ExerciseProgressOption extends Equatable {
  const ExerciseProgressOption({
    required this.id,
    required this.mx,
    required this.unitKind,
  });

  factory ExerciseProgressOption.fromJson(Map<String, Object?> json) {
    return ExerciseProgressOption(
      id: (json['id'] as String?) ?? '',
      mx: (json['mx'] as num?)?.toDouble() ?? 0.0,
      unitKind: (json['unitKind'] as String?) ?? 'unit',
    );
  }

  /// Exercise id.
  final String id;

  /// Best value (weight, reps, speed, or seconds).
  final double mx;

  /// One of: 'kmh' | 's' | 'reps' | 'unit'.
  final String unitKind;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'mx': mx,
        'unitKind': unitKind,
      };

  @override
  List<Object?> get props => <Object?>[id, mx, unitKind];
}

/// A row in the recent-session list shown below the exercise chart.
class ExerciseProgressRow extends Equatable {
  const ExerciseProgressRow({
    this.d,
    this.sets = const <SetEntry>[],
    this.target,
  });

  factory ExerciseProgressRow.fromJson(Map<String, Object?> json) {
    final List<Object?> rawSets = (json['sets'] as List<Object?>?) ?? <Object?>[];
    final Object? rawTarget = json['target'];
    return ExerciseProgressRow(
      d: json['d'] as String?,
      sets: rawSets
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => SetEntry.fromJson(m.cast<String, Object?>()))
          .toList(),
      target: rawTarget is Map<Object?, Object?>
          ? RoutineExercise.fromJson(rawTarget.cast<String, Object?>())
          : null,
    );
  }

  final String? d;
  final List<SetEntry> sets;
  final RoutineExercise? target;

  Map<String, Object?> toJson() => <String, Object?>{
        'd': d,
        'sets': sets.map((SetEntry s) => s.toJson()).toList(),
        'target': target?.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[d, sets, target];
}

/// All-time best 1RM estimate returned by `viewAgg.exerciseProgress` `e1Best`.
/// Mirrors openGym `onerm.js` `best1RM()` return shape: {est, w, r, d, t}.
class E1Best extends Equatable {
  const E1Best({
    required this.est,
    required this.w,
    required this.r,
    required this.d,
    required this.t,
  });

  factory E1Best.fromJson(Map<String, Object?> json) {
    return E1Best(
      est: (json['est'] as num?)?.toDouble() ?? 0.0,
      w: (json['w'] as num?) ?? 0,
      r: (json['r'] as num?) ?? 0,
      d: (json['d'] as String?) ?? '',
      t: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  final double est;
  final num w;
  final num r;
  final String d;
  final int t;

  Map<String, Object?> toJson() => <String, Object?>{
        'est': est,
        'w': w,
        'r': r,
        'd': d,
        't': t,
      };

  @override
  List<Object?> get props => <Object?>[est, w, r, d, t];
}

/// Full exercise progress result from the Stats card.
class ExerciseProgress extends Equatable {
  const ExerciseProgress({
    required this.exHist,
    this.curEx,
    required this.curMode,
    required this.repsOnly,
    required this.unitKind,
    required this.exPts,
    required this.exList,
    required this.exBest,
    required this.e1Pts,
    this.e1Best,
    required this.effPts,
    required this.showE1,
    required this.showEff,
  });

  factory ExerciseProgress.fromJson(Map<String, Object?> json) {
    final List<Object?> rawExHist = (json['exHist'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawExPts = (json['exPts'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawExList = (json['exList'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawE1Pts = (json['e1Pts'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawEffPts = (json['effPts'] as List<Object?>?) ?? <Object?>[];
    final Object? rawE1Best = json['e1Best'];

    return ExerciseProgress(
      exHist: rawExHist
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ExerciseProgressOption.fromJson(m.cast<String, Object?>()))
          .toList(),
      curEx: json['curEx'] as String?,
      curMode: (json['curMode'] as String?) ?? 'reps',
      repsOnly: json['repsOnly'] == true,
      unitKind: (json['unitKind'] as String?) ?? 'unit',
      exPts: rawExPts
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ChartPoint.fromJson(m.cast<String, Object?>()))
          .toList(),
      exList: rawExList
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ExerciseProgressRow.fromJson(m.cast<String, Object?>()))
          .toList(),
      exBest: (json['exBest'] as num?)?.toDouble() ?? 0.0,
      e1Pts: rawE1Pts
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ChartPoint.fromJson(m.cast<String, Object?>()))
          .toList(),
      e1Best: rawE1Best is Map<Object?, Object?>
          ? E1Best.fromJson(rawE1Best.cast<String, Object?>())
          : null,
      effPts: rawEffPts
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ChartPoint.fromJson(m.cast<String, Object?>()))
          .toList(),
      showE1: json['showE1'] == true,
      showEff: json['showEff'] == true,
    );
  }

  final List<ExerciseProgressOption> exHist;
  final String? curEx;
  final String curMode;
  final bool repsOnly;
  final String unitKind;
  final List<ChartPoint> exPts;
  final List<ExerciseProgressRow> exList;
  final double exBest;
  final List<ChartPoint> e1Pts;
  final E1Best? e1Best;
  final List<ChartPoint> effPts;
  final bool showE1;
  final bool showEff;

  Map<String, Object?> toJson() => <String, Object?>{
        'exHist': exHist.map((ExerciseProgressOption o) => o.toJson()).toList(),
        'curEx': curEx,
        'curMode': curMode,
        'repsOnly': repsOnly,
        'unitKind': unitKind,
        'exPts': exPts.map((ChartPoint p) => p.toJson()).toList(),
        'exList': exList.map((ExerciseProgressRow r) => r.toJson()).toList(),
        'exBest': exBest,
        'e1Pts': e1Pts.map((ChartPoint p) => p.toJson()).toList(),
        'e1Best': e1Best?.toJson(),
        'effPts': effPts.map((ChartPoint p) => p.toJson()).toList(),
        'showE1': showE1,
        'showEff': showEff,
      };

  @override
  List<Object?> get props => <Object?>[
        exHist, curEx, curMode, repsOnly, unitKind,
        exPts, exList, exBest, e1Pts, e1Best, effPts, showE1, showEff,
      ];
}


// ---------------------------------------------------------------------------
// Calendar model
// ---------------------------------------------------------------------------

/// Monthly aggregates for the calendar sheet.
class CalendarMonthTotals extends Equatable {
  const CalendarMonthTotals({
    required this.count,
    required this.vol,
    required this.ms,
  });

  factory CalendarMonthTotals.fromJson(Map<String, Object?> json) {
    return CalendarMonthTotals(
      count: (json['count'] as num?)?.toInt() ?? 0,
      vol: (json['vol'] as num?) ?? 0,
      ms: (json['ms'] as num?)?.toInt() ?? 0,
    );
  }

  final int count;
  final num vol;
  final int ms;

  Map<String, Object?> toJson() => <String, Object?>{
        'count': count,
        'vol': vol,
        'ms': ms,
      };

  @override
  List<Object?> get props => <Object?>[count, vol, ms];
}

// ---------------------------------------------------------------------------
// Workout detail groups models
// ---------------------------------------------------------------------------

/// A single per-routine group in the WorkoutDetail sheet.
class WorkoutDetailGroup extends Equatable {
  const WorkoutDetailGroup({
    required this.key,
    this.rid,
    required this.items,
    required this.setN,
    required this.vol,
  });

  factory WorkoutDetailGroup.fromJson(Map<String, Object?> json) {
    final List<Object?> rawItems = (json['items'] as List<Object?>?) ?? <Object?>[];
    return WorkoutDetailGroup(
      key: (json['key'] as String?) ?? '__none',
      rid: json['rid'] as String?,
      items: rawItems.whereType<num>().map((num n) => n.toInt()).toList(),
      setN: (json['setN'] as num?)?.toInt() ?? 0,
      vol: (json['vol'] as num?) ?? 0,
    );
  }

  final String key;
  final String? rid;
  final List<int> items;
  final int setN;
  final num vol;

  Map<String, Object?> toJson() => <String, Object?>{
        'key': key,
        'rid': rid,
        'items': items,
        'setN': setN,
        'vol': vol,
      };

  @override
  List<Object?> get props => <Object?>[key, rid, items, setN, vol];
}

/// Full grouped result for the WorkoutDetail sheet.
class WorkoutDetailGroups extends Equatable {
  const WorkoutDetailGroups({
    required this.grouped,
    required this.groups,
  });

  factory WorkoutDetailGroups.fromJson(Map<String, Object?> json) {
    final List<Object?> rawGroups = (json['groups'] as List<Object?>?) ?? <Object?>[];
    return WorkoutDetailGroups(
      grouped: json['grouped'] == true,
      groups: rawGroups
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => WorkoutDetailGroup.fromJson(m.cast<String, Object?>()))
          .toList(),
    );
  }

  final bool grouped;
  final List<WorkoutDetailGroup> groups;

  Map<String, Object?> toJson() => <String, Object?>{
        'grouped': grouped,
        'groups': groups.map((WorkoutDetailGroup g) => g.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[grouped, groups];
}

// ---------------------------------------------------------------------------
// Bodyweight goal model
// ---------------------------------------------------------------------------

/// Goal proximity computed from the last bodyweight entry.
class BwGoal extends Equatable {
  const BwGoal({
    required this.gap,
    required this.reached,
    required this.gain,
  });

  factory BwGoal.fromJson(Map<String, Object?> json) {
    return BwGoal(
      gap: (json['gap'] as num?)?.toDouble() ?? 0.0,
      reached: json['reached'] == true,
      gain: json['gain'] == true,
    );
  }

  final double gap;
  final bool reached;
  final bool gain;

  Map<String, Object?> toJson() => <String, Object?>{
        'gap': gap,
        'reached': reached,
        'gain': gain,
      };

  @override
  List<Object?> get props => <Object?>[gap, reached, gain];
}

// ---------------------------------------------------------------------------
// Home view model
// ---------------------------------------------------------------------------

/// All derived values shown on the Home screen.
class HomeView extends Equatable {
  const HomeView({
    this.delta,
    this.deltaAbs,
    required this.wThisWeek,
    required this.plannedPerWeek,
    required this.bwPoints,
    this.goal,
  });

  factory HomeView.fromJson(Map<String, Object?> json) {
    final List<Object?> rawBwPts = (json['bwPoints'] as List<Object?>?) ?? <Object?>[];
    final Object? rawGoal = json['goal'];
    return HomeView(
      delta: json['delta'] as num?,
      deltaAbs: json['deltaAbs'] as num?,
      wThisWeek: (json['wThisWeek'] as num?)?.toInt() ?? 0,
      plannedPerWeek: (json['plannedPerWeek'] as num?)?.toInt() ?? 0,
      bwPoints: rawBwPts
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => ChartPoint.fromJson(m.cast<String, Object?>()))
          .toList(),
      goal: rawGoal is Map<Object?, Object?>
          ? BwGoal.fromJson(rawGoal.cast<String, Object?>())
          : null,
    );
  }

  final num? delta;
  final num? deltaAbs;
  final int wThisWeek;
  final int plannedPerWeek;
  final List<ChartPoint> bwPoints;
  final BwGoal? goal;

  Map<String, Object?> toJson() => <String, Object?>{
        'delta': delta,
        'deltaAbs': deltaAbs,
        'wThisWeek': wThisWeek,
        'plannedPerWeek': plannedPerWeek,
        'bwPoints': bwPoints.map((ChartPoint p) => p.toJson()).toList(),
        'goal': goal?.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[delta, deltaAbs, wThisWeek, plannedPerWeek, bwPoints, goal];
}
