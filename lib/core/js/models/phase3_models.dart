// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/routine.dart';
import '../../models/set_entry.dart';
import '../../models/state_parts.dart';
import '../../models/workout.dart';

/// Quick-pick effort preset from openGym `effort.js` `EFFORT_PRESETS`.
class EffortPreset extends Equatable {
  const EffortPreset({
    required this.rir,
    required this.color,
    required this.feel,
    required this.tail,
  });

  factory EffortPreset.fromJson(Map<String, Object?> json) {
    return EffortPreset(
      rir: (json['rir'] as num?) ?? 0,
      color: (json['color'] as String?) ?? '',
      feel: (json['feel'] as String?) ?? '',
      tail: json['tail'] == true,
    );
  }

  final num rir;
  final String color;
  final String feel;
  final bool tail;

  Map<String, Object?> toJson() => <String, Object?>{
        'rir': rir,
        'color': color,
        'feel': feel,
        'tail': tail,
      };

  @override
  List<Object?> get props => <Object?>[rir, color, feel, tail];
}

/// Starter plan option from openGym `starter.js` `starterPlanOptions()`.
class StarterPlanOption extends Equatable {
  const StarterPlanOption({
    required this.id,
    required this.days,
  });

  factory StarterPlanOption.fromJson(Map<String, Object?> json) {
    return StarterPlanOption(
      id: (json['id'] as String?) ?? '',
      days: (json['days'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final int days;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'days': days,
      };

  @override
  List<Object?> get props => <Object?>[id, days];
}

/// A day-to-routine mapping in a starter plan schedule.
class StarterScheduleItem extends Equatable {
  const StarterScheduleItem({
    required this.day,
    required this.routineId,
  });

  factory StarterScheduleItem.fromJson(Map<String, Object?> json) {
    return StarterScheduleItem(
      day: (json['day'] as num?)?.toInt() ?? 0,
      routineId: (json['routineId'] as String?) ?? '',
    );
  }

  final int day;
  final String routineId;

  Map<String, Object?> toJson() => <String, Object?>{
        'day': day,
        'routineId': routineId,
      };

  @override
  List<Object?> get props => <Object?>[day, routineId];
}

/// Built starter plan from openGym `starter.js` `buildStarterPlan()`.
class StarterPlan extends Equatable {
  const StarterPlan({
    required this.routines,
    required this.schedule,
  });

  factory StarterPlan.fromJson(Map<String, Object?> json) {
    final List<Object?> rawRoutines = (json['routines'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawSchedule = (json['schedule'] as List<Object?>?) ?? <Object?>[];
    return StarterPlan(
      routines: rawRoutines
          .whereType<Map<String, Object?>>()
          .map(Routine.fromJson)
          .toList(),
      schedule: rawSchedule
          .whereType<Map<String, Object?>>()
          .map(StarterScheduleItem.fromJson)
          .toList(),
    );
  }

  final List<Routine> routines;
  final List<StarterScheduleItem> schedule;

  Map<String, Object?> toJson() => <String, Object?>{
        'routines': routines.map((Routine r) => r.toJson()).toList(),
        'schedule': schedule.map((StarterScheduleItem s) => s.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[routines, schedule];
}

/// Chart point for exercise history series (`exerciseHistory`).
class ExerciseHistoryPoint extends Equatable {
  const ExerciseHistoryPoint({
    required this.t,
    required this.d,
    required this.y,
    this.e1rm,
  });

  factory ExerciseHistoryPoint.fromJson(Map<String, Object?> json) {
    return ExerciseHistoryPoint(
      t: (json['t'] as num?) ?? 0,
      d: (json['d'] as String?) ?? '',
      y: (json['y'] as num?) ?? 0,
      e1rm: json['e1rm'] as num?,
    );
  }

  final num t;
  final String d;
  final num y;
  final num? e1rm;

  Map<String, Object?> toJson() => <String, Object?>{
        't': t,
        'd': d,
        'y': y,
        if (e1rm != null) 'e1rm': e1rm,
      };

  @override
  List<Object?> get props => <Object?>[t, d, y, e1rm];
}

/// Historical session item for exercise detail list.
class ExerciseHistorySession extends Equatable {
  const ExerciseHistorySession({
    required this.id,
    required this.d,
    required this.t,
    required this.mode,
    this.target,
    this.sets = const <SetEntry>[],
    this.value,
    this.e1rm,
    this.volume,
    this.pr = false,
  });

  factory ExerciseHistorySession.fromJson(Map<String, Object?> json) {
    final Object? rawTarget = json['target'];
    final List<Object?> rawSets = (json['sets'] as List<Object?>?) ?? <Object?>[];
    return ExerciseHistorySession(
      id: (json['id'] as String?) ?? '',
      d: (json['d'] as String?) ?? '',
      t: (json['t'] as num?) ?? 0,
      mode: (json['mode'] as String?) ?? '',
      target: rawTarget is Map<String, Object?> ? RoutineExercise.fromJson(rawTarget) : null,
      sets: rawSets
          .whereType<Map<String, Object?>>()
          .map(SetEntry.fromJson)
          .toList(),
      value: json['value'] as num?,
      e1rm: json['e1rm'] as num?,
      volume: json['volume'] as num?,
      pr: json['pr'] == true,
    );
  }

  final String id;
  final String d;
  final num t;
  final String mode;
  final RoutineExercise? target;
  final List<SetEntry> sets;
  final num? value;
  final num? e1rm;
  final num? volume;
  final bool pr;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'd': d,
        't': t,
        'mode': mode,
        if (target != null) 'target': target!.toJson(),
        'sets': sets.map((SetEntry s) => s.toJson()).toList(),
        'value': value,
        'e1rm': e1rm,
        'volume': volume,
        'pr': pr,
      };

  @override
  List<Object?> get props => <Object?>[id, d, t, mode, target, sets, value, e1rm, volume, pr];
}

/// Aggregated exercise history result from openGym `exerciseHistory()`.
class ExerciseHistoryResult extends Equatable {
  const ExerciseHistoryResult({
    required this.mode,
    required this.metric,
    required this.best,
    this.prId,
    required this.total,
    this.sessions = const <ExerciseHistorySession>[],
    this.points = const <ExerciseHistoryPoint>[],
    this.e1rmPoints = const <ExerciseHistoryPoint>[],
  });

  factory ExerciseHistoryResult.fromJson(Map<String, Object?> json) {
    final List<Object?> rawSessions = (json['sessions'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawPoints = (json['points'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawE1rmPoints = (json['e1rmPoints'] as List<Object?>?) ?? <Object?>[];

    return ExerciseHistoryResult(
      mode: (json['mode'] as String?) ?? 'reps',
      metric: (json['metric'] as String?) ?? 'weight',
      best: (json['best'] as num?) ?? 0,
      prId: json['prId'] as String?,
      total: (json['total'] as num?)?.toInt() ?? 0,
      sessions: rawSessions
          .whereType<Map<String, Object?>>()
          .map(ExerciseHistorySession.fromJson)
          .toList(),
      points: rawPoints
          .whereType<Map<String, Object?>>()
          .map(ExerciseHistoryPoint.fromJson)
          .toList(),
      e1rmPoints: rawE1rmPoints
          .whereType<Map<String, Object?>>()
          .map(ExerciseHistoryPoint.fromJson)
          .toList(),
    );
  }

  final String mode;
  final String metric;
  final num best;
  final String? prId;
  final int total;
  final List<ExerciseHistorySession> sessions;
  final List<ExerciseHistoryPoint> points;
  final List<ExerciseHistoryPoint> e1rmPoints;

  Map<String, Object?> toJson() => <String, Object?>{
        'mode': mode,
        'metric': metric,
        'best': best,
        'prId': prId,
        'total': total,
        'sessions': sessions.map((ExerciseHistorySession s) => s.toJson()).toList(),
        'points': points.map((ExerciseHistoryPoint p) => p.toJson()).toList(),
        'e1rmPoints': e1rmPoints.map((ExerciseHistoryPoint p) => p.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[mode, metric, best, prId, total, sessions, points, e1rmPoints];
}

/// 1RM record summary from openGym `doFinishWorkout` `e1prs`.
class E1rmRecordSummary extends Equatable {
  const E1rmRecordSummary({
    required this.id,
    required this.est,
    required this.w,
    required this.r,
    required this.prev,
  });

  factory E1rmRecordSummary.fromJson(Map<String, Object?> json) {
    return E1rmRecordSummary(
      id: (json['id'] as String?) ?? '',
      est: (json['est'] as num?) ?? 0,
      w: (json['w'] as num?) ?? 0,
      r: (json['r'] as num?) ?? 0,
      prev: (json['prev'] as num?) ?? 0,
    );
  }

  final String id;
  final num est;
  final num w;
  final num r;
  final num prev;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'est': est,
        'w': w,
        'r': r,
        'prev': prev,
      };

  @override
  List<Object?> get props => <Object?>[id, est, w, r, prev];
}

/// Result of completing a workout from openGym `finish.completeWorkout`.
class FinishResult extends Equatable {
  const FinishResult({
    required this.workout,
    required this.prs,
    required this.e1prs,
    required this.exWeights,
    this.past = false,
    this.replaceId,
  });

  factory FinishResult.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> rawWorkout = (json['workout'] as Map<String, Object?>?) ?? <String, Object?>{};
    final List<Object?> rawPrs = (json['prs'] as List<Object?>?) ?? <Object?>[];
    final List<Object?> rawE1prs = (json['e1prs'] as List<Object?>?) ?? <Object?>[];
    final Map<String, Object?> rawExWeights = (json['exWeights'] as Map<String, Object?>?) ?? <String, Object?>{};

    final Map<String, ExWeight> exWeights = <String, ExWeight>{};
    for (final MapEntry<String, Object?> entry in rawExWeights.entries) {
      if (entry.value case final Map<String, Object?> m) {
        exWeights[entry.key] = ExWeight.fromJson(m);
      }
    }

    return FinishResult(
      workout: Workout.fromJson(rawWorkout),
      prs: rawPrs.whereType<String>().toList(),
      e1prs: rawE1prs
          .whereType<Map<String, Object?>>()
          .map(E1rmRecordSummary.fromJson)
          .toList(),
      exWeights: exWeights,
      past: json['past'] == true,
      replaceId: json['replaceId'] as String?,
    );
  }

  final Workout workout;
  final List<String> prs;
  final List<E1rmRecordSummary> e1prs;
  final Map<String, ExWeight> exWeights;
  final bool past;
  final String? replaceId;

  Map<String, Object?> toJson() => <String, Object?>{
        'workout': workout.toJson(),
        'prs': prs,
        'e1prs': e1prs.map((E1rmRecordSummary e) => e.toJson()).toList(),
        'exWeights': exWeights.map((String k, ExWeight v) => MapEntry<String, Object?>(k, v.toJson())),
        'past': past,
        'replaceId': replaceId,
      };

  @override
  List<Object?> get props => <Object?>[workout, prs, e1prs, exWeights, past, replaceId];
}
