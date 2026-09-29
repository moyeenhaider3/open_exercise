// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/models/progression_models.dart';
import 'package:open_exercise/core/js/modules/effort_js.dart';
import 'package:open_exercise/core/js/modules/exercise_history_js.dart';
import 'package:open_exercise/core/js/modules/finish_workout_js.dart';
import 'package:open_exercise/core/js/modules/muscles_js.dart';
import 'package:open_exercise/core/js/modules/progression_copy_js.dart';
import 'package:open_exercise/core/js/modules/rep_range_js.dart';
import 'package:open_exercise/core/js/modules/starter_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/set_entry.dart';

import '../parity_types.dart';

Map<String, ParityCall> phase3Dispatch(JsEngineService engine) {
  final MusclesJs muscles = engine.muscles;
  final EffortJs effort = engine.effort;
  final StarterJs starter = engine.starter;
  final ExerciseHistoryJs exerciseHistory = engine.exerciseHistory;
  final RepRangeJs repRange = engine.repRange;
  final ProgressionCopyJs progressionCopy = engine.progressionCopy;
  final FinishWorkoutJs finish = engine.finish;

  return <String, ParityCall>{
    // Muscles
    'muscles.inMuscleOrder': (List<Object?> args) {
      final List<Object?> rawList = argAt(args, 0) as List<Object?>;
      final List<String> list = rawList.map((Object? e) => e.toString()).toList();
      return toPlainJson(muscles.inMuscleOrder(list));
    },
    'muscles.hasExplicitMuscleMetadata': (List<Object?> args) {
      final Map<String, Object?> ex = jsonMapArg(args, 0);
      return toPlainJson(muscles.hasExplicitMuscleMetadata(ex));
    },
    'muscles.normalizeMuscleGroups': (List<Object?> args) {
      final Map<String, Object?> ex = jsonMapArg(args, 0);
      return toPlainJson(muscles.normalizeMuscleGroups(ex));
    },
    'muscles.exerciseMuscleSnapshot': (List<Object?> args) {
      final Map<String, Object?> ex = jsonMapArg(args, 0);
      return toPlainJson(muscles.exerciseMuscleSnapshot(ex));
    },

    // Effort
    'effort.rirOf': (List<Object?> args) {
      final Map<String, Object?> rawSet = jsonMapArg(args, 0);
      final SetEntry s = SetEntry.fromJson(rawSet);
      return toPlainJson(effort.rirOf(s));
    },
    'effort.toScale': (List<Object?> args) {
      final String kind = argAt(args, 0) as String;
      final num? rir = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      return toPlainJson(effort.toScale(kind, rir));
    },
    'effort.effortColor': (List<Object?> args) {
      final num? rir = hasArg(args, 0) ? argAt(args, 0) as num? : null;
      return toPlainJson(effort.effortColor(rir));
    },
    'effort.hasEffort': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      return toPlainJson(effort.hasEffort(s));
    },
    'effort.displayScale': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      return toPlainJson(effort.displayScale(s));
    },
    'effort.scaleName': (List<Object?> args) {
      final String kind = argAt(args, 0) as String;
      return toPlainJson(effort.scaleName(kind));
    },
    'effort.avgRir': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<SetEntry> sets = rawList
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => SetEntry.fromJson(m.cast<String, Object?>()))
          .toList();
      return toPlainJson(effort.avgRir(sets));
    },
    'effort.effortSummary': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int days = (argAt(args, 1) as num).toInt();
      return toPlainJson(effort.effortSummary(s, days).toJson());
    },
    'effort.effortWeeks': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int days = (argAt(args, 1) as num).toInt();
      return toPlainJson(effort.effortWeeks(s, days).map((e) => e.toJson()).toList());
    },
    'effort.effortHistogram': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int days = (argAt(args, 1) as num).toInt();
      return toPlainJson(effort.effortHistogram(s, days).map((e) => e.toJson()).toList());
    },
    'effort.isHardSet': (List<Object?> args) {
      final Map<String, Object?> rawSet = jsonMapArg(args, 0);
      final SetEntry s = SetEntry.fromJson(rawSet);
      return toPlainJson(effort.isHardSet(s));
    },

    // Starter
    'starter.starterPlanOptions': (List<Object?> args) {
      return toPlainJson(starter.starterPlanOptions().map((o) => o.toJson()).toList());
    },
    'starter.starterPlanDays': (List<Object?> args) {
      final String id = argAt(args, 0) as String;
      return toPlainJson(starter.starterPlanDays(id));
    },
    'starter.buildStarterPlan': (List<Object?> args) {
      final String id = argAt(args, 0) as String;
      return toPlainJson(starter.buildStarterPlan(id)?.toJson());
    },

    // Exercise History
    'exerciseHistory.exerciseHistory': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(exerciseHistory.exerciseHistory(s, exId).toJson());
    },

    // Rep Range
    'repRange.normalizeRepRange': (List<Object?> args) {
      final num? reps = hasArg(args, 0) ? argAt(args, 0) as num? : null;
      final num? repsMin = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      final int? stride = hasArg(args, 2) ? (argAt(args, 2) as num?)?.toInt() : null;
      final ({int reps, int repsMin}) res = repRange.normalizeRepRange(reps, repsMin, stride);
      return <String, Object?>{
        'reps': res.reps,
        'repsMin': res.repsMin,
      };
    },

    // Progression Copy
    'progressionCopy.progressionGuidance': (List<Object?> args) {
      final Map<String, Object?>? map = hasArg(args, 0) && argAt(args, 0) is Map
          ? (argAt(args, 0) as Map).cast<String, Object?>()
          : null;
      final Prescription? plan = map != null ? Prescription.fromJson(map) : null;
      final ({String policyLabel, Object? why})? res = progressionCopy.progressionGuidance(plan);
      if (res == null) return null;
      return <String, Object?>{
        'policyLabel': res.policyLabel,
        'why': res.why,
      };
    },

    // Finish Workout
    'finish.completeWorkout': (List<Object?> args) {
      final GymState st = GymState.fromJson(jsonMapArg(args, 0));
      final int endMs = hasArg(args, 1) ? (argAt(args, 1) as num).toInt() : 0;
      return toPlainJson(finish.completeWorkout(st, endMs).toJson());
    },
  };
}
