// SPDX-License-Identifier: AGPL-3.0-or-later

import 'gym_state.dart';
import 'routine.dart';
import 'set_entry.dart';
import 'workout.dart';

/// Weekly plan accessors mirroring openGym `../openGym/frontend/src/views/Plan.jsx`.
extension GymStateWeek on GymState {
  /// Reads routine ids for weekday [day] (0=Sunday ... 6=Saturday, JS `Date.getDay()` index).
  /// Mirrors openGym `Plan.jsx`: `[].concat(S.week[d] || [])`.
  List<String> weekRoutineIds(int day) {
    final String key = day.toString();
    final Object? val = week?[key] ?? (extra['week'] is Map ? (extra['week'] as Map)[key] : null);
    if (val case final String s) {
      return <String>[s];
    }
    if (val case final List<Object?> list) {
      return list.whereType<String>().toList();
    }
    return const <String>[];
  }

  /// Sets or clears routine ids for weekday [day].
  /// Mirrors openGym `Plan.jsx` `removeFromDay`: an empty list removes the day key ("never store []").
  GymState withWeekDay(int day, List<String> ids) {
    final Map<String, Object> nextWeek = Map<String, Object>.from(week ?? const <String, Object>{});
    final String key = day.toString();
    if (ids.isEmpty) {
      nextWeek.remove(key);
    } else {
      nextWeek[key] = List<String>.unmodifiable(ids);
    }
    return copyWith(week: nextWeek);
  }
}

/// Extra-backed accessors for [WorkoutEntry] fields used in openGym.
extension WorkoutEntryExtras on WorkoutEntry {
  /// Target routine exercise configuration.
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 517-560: `entry.target`.
  RoutineExercise? get target {
    final Object? raw = extra['target'];
    return raw is Map<String, Object?> ? RoutineExercise.fromJson(raw) : null;
  }

  /// Per-entry note.
  /// Mirrors `../openGym/frontend/src/lib/finish-workout.js` / `Workout.jsx`: `entry.note`.
  String? get note => extra['note'] as String?;

  /// Historical workout date when entry was fetched via lastEntryFor.
  String? get d => extra['d'] as String?;

  /// Whether the note is pinned across workouts.
  /// Mirrors `../openGym/frontend/src/lib/finish-workout.js`: `entry.notePin`.
  bool get notePin => extra['notePin'] == true;

  /// Whether to exclude this entry from progression calculations.
  /// Mirrors `../openGym/frontend/src/lib/finish-workout.js`: `entry.noProg`.
  bool get noProg => extra['noProg'] == true;

  /// Per-entry plan configuration.
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 625-665: `entry.plan`.
  Map<String, Object?>? get plan {
    final Object? raw = extra['plan'];
    return raw is Map<String, Object?> ? raw : null;
  }

  /// Sets or removes keys in [extra] only.
  /// Removing a key deletes it; typed fields are never duplicated into extra.
  WorkoutEntry withExtraFields(Map<String, Object?> set, {Iterable<String>? remove}) {
    final Map<String, Object?> nextExtra = Map<String, Object?>.from(extra);
    if (remove != null) {
      for (final String key in remove) {
        nextExtra.remove(key);
      }
    }
    for (final MapEntry<String, Object?> entry in set.entries) {
      if (!WorkoutEntry.knownKeys.contains(entry.key)) {
        nextExtra[entry.key] = entry.value;
      }
    }
    return copyWith(extra: nextExtra);
  }
}

/// Extra-backed accessors for [Workout] fields used in openGym.
extension WorkoutExtras on Workout {
  /// Active workout view mode (e.g. `'cards'`, `'list'`, `'compact'`).
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 517-560: `active.workoutView`.
  String? get workoutView => extra['workoutView'] as String?;

  /// Backfill metadata map (`{durationMin, replaceId}`), or null if live.
  /// Mirrors `../openGym/frontend/src/sheets.jsx`: `active.backfill`.
  Map<String, Object?>? get backfill {
    final Object? val = extra['backfill'];
    if (val is Map) {
      return Map<String, Object?>.from(val);
    }
    return null;
  }

  /// Whether this is a backfilled workout.
  bool get isBackfill => backfill != null;

  /// Backfill duration in minutes if this is a backfilled workout.
  num? get backfillDurationMin => backfill?['durationMin'] as num?;

  /// ID of workout being replaced if backfill is replacing a same-day workout.
  String? get backfillReplaceId => backfill?['replaceId'] as String?;

  /// Workout-level note.
  /// Mirrors `../openGym/frontend/src/lib/finish-workout.js`: `active.note`.
  String? get note => extra['note'] as String?;

  /// Whether the workout has a custom user-assigned name.
  /// Mirrors `../openGym/frontend/src/sheets.jsx`: `active.customName`.
  bool get customName => extra['customName'] == true;

  /// Sets or removes keys in [extra] only.
  /// Removing a key deletes it; typed fields are never duplicated into extra.
  Workout withExtraFields(Map<String, Object?> set, {Iterable<String>? remove}) {
    final Map<String, Object?> nextExtra = Map<String, Object?>.from(extra);
    if (remove != null) {
      for (final String key in remove) {
        nextExtra.remove(key);
      }
    }
    for (final MapEntry<String, Object?> entry in set.entries) {
      if (!Workout.knownKeys.contains(entry.key)) {
        nextExtra[entry.key] = entry.value;
      }
    }
    return copyWith(extra: nextExtra);
  }
}

/// Extra-backed accessors for [SetEntry] fields used in openGym.
extension SetEntryExtras on SetEntry {
  /// Time duration in seconds for timed sets.
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 517-560: `set.sec`.
  num? get sec => extra['sec'] is num ? extra['sec'] as num : null;

  /// Time duration in minutes for cardio/timed sets.
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 517-560: `set.min`.
  num? get min => extra['min'] is num ? extra['min'] as num : null;

  /// Speed setting for cardio sets.
  /// Mirrors `../openGym/frontend/src/views/Workout.jsx` lines 517-560: `set.speed`.
  num? get speed => extra['speed'] is num ? extra['speed'] as num : null;

  /// Sets or removes keys in [extra] only.
  /// Removing a key deletes it; typed fields are never duplicated into extra.
  SetEntry withExtraFields(Map<String, Object?> set, {Iterable<String>? remove}) {
    final Map<String, Object?> nextExtra = Map<String, Object?>.from(extra);
    if (remove != null) {
      for (final String key in remove) {
        nextExtra.remove(key);
      }
    }
    for (final MapEntry<String, Object?> entry in set.entries) {
      if (!SetEntry.knownKeys.contains(entry.key)) {
        nextExtra[entry.key] = entry.value;
      }
    }
    return copyWith(extra: nextExtra);
  }
}

/// Extra-backed accessors for [Routine] fields used in openGym.
extension RoutineExtras on Routine {
  /// Routine-level progression override identifier.
  /// Mirrors `../openGym/frontend/src/views/RoutineEdit.jsx`: `routine.prog`.
  String? get prog => extra['prog'] as String?;

  /// Whether this routine is excluded from automatic progression.
  /// Mirrors `../openGym/frontend/src/views/RoutineEdit.jsx`: `routine.excludeFromProgression`.
  bool get excludeFromProgression => extra['excludeFromProgression'] == true;

  /// Sets or removes keys in [extra] only.
  /// Removing a key deletes it; typed fields are never duplicated into extra.
  Routine withExtraFields(Map<String, Object?> set, {Iterable<String>? remove}) {
    final Map<String, Object?> nextExtra = Map<String, Object?>.from(extra);
    if (remove != null) {
      for (final String key in remove) {
        nextExtra.remove(key);
      }
    }
    for (final MapEntry<String, Object?> entry in set.entries) {
      if (!Routine.knownKeys.contains(entry.key)) {
        nextExtra[entry.key] = entry.value;
      }
    }
    return copyWith(extra: nextExtra);
  }
}

/// Extra-backed accessors for [RoutineExercise] fields used in openGym.
extension RoutineExerciseExtras on RoutineExercise {
  /// Exercise tracking mode.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.mode`.
  String? get mode => extra['mode'] as String?;

  /// Rest timer override in seconds.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.restSec`.
  num? get restSec => extra['restSec'] is num ? extra['restSec'] as num : null;

  /// Time duration in seconds for timed exercises.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.sec`.
  num? get sec => extra['sec'] is num ? extra['sec'] as num : null;

  /// Time duration in minutes for cardio exercises.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.min`.
  num? get min => extra['min'] is num ? extra['min'] as num : null;

  /// Speed setting for cardio exercises.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.speed`.
  num? get speed => extra['speed'] is num ? extra['speed'] as num : null;

  /// Bodyweight offset or percent.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.bw`.
  num? get bw => extra['bw'] is num ? extra['bw'] as num : null;

  /// Progression step increment override.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.inc`.
  num? get inc => extra['inc'] is num ? extra['inc'] as num : null;

  /// Minimum reps for rep-range / double progression.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.repsMin`.
  num? get repsMin => extra['repsMin'] is num ? extra['repsMin'] as num : null;

  /// Number of planned warm-up sets.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.warmups`.
  num? get warmups => extra['warmups'] is num ? extra['warmups'] as num : null;

  /// Whether unilateral per-side logging is forced on.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.perSide`.
  bool get perSide => extra['perSide'] == true;

  /// Per-exercise progression policy override.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.prog`.
  String? get prog => extra['prog'] as String?;

  /// Deload factor override.
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.deloadFactor`.
  num? get deloadFactor => extra['deloadFactor'] is num ? extra['deloadFactor'] as num : null;

  /// Intensifier plan (drop sets, rest-pause).
  /// Mirrors `../openGym/frontend/src/sheets.jsx` ExConfig lines 1175-1422: `ex.plan`.
  Map<String, Object?>? get plan =>
      extra['plan'] is Map<String, Object?> ? extra['plan'] as Map<String, Object?> : null;

  /// Sets or removes keys in [extra] only.
  /// Removing a key deletes it; typed fields are never duplicated into extra.
  RoutineExercise withExtraFields(Map<String, Object?> set, {Iterable<String>? remove}) {
    final Map<String, Object?> nextExtra = Map<String, Object?>.from(extra);
    if (remove != null) {
      for (final String key in remove) {
        nextExtra.remove(key);
      }
    }
    for (final MapEntry<String, Object?> entry in set.entries) {
      if (!RoutineExercise.knownKeys.contains(entry.key)) {
        nextExtra[entry.key] = entry.value;
      }
    }
    return copyWith(extra: nextExtra);
  }
}
