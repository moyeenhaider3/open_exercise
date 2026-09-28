// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/models/recovery_models.dart';
import 'package:open_exercise/core/js/modules/recovery_js.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> recoveryDispatch(JsEngineService engine) {
  final RecoveryJs recovery = engine.recovery;

  return <String, ParityCall>{
    'recovery.halfLifeDecay': (List<Object?> args) {
      final num ageMs = argAt(args, 0) as num;
      final num halfLifeMs = argAt(args, 1) as num;
      return toPlainJson(recovery.halfLifeDecay(ageMs, halfLifeMs));
    },
    'recovery.fatigueOf': (List<Object?> args) {
      final List<Object?> rawWorkouts = jsonListArg(args, 0);
      final List<Workout> workouts = rawWorkouts
          .map((Object? item) => Workout.fromJson(item as Map<String, Object?>))
          .toList();
      final int nowMs = (argAt(args, 1) as num).toInt();
      final RecoveryOptions? opts = hasArg(args, 2) && argAt(args, 2) != null
          ? RecoveryOptions.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(recovery.fatigueOf(workouts, nowMs, opts: opts));
    },
    'recovery.strengthOf': (List<Object?> args) {
      final List<Object?> rawWorkouts = jsonListArg(args, 0);
      final List<Workout> workouts = rawWorkouts
          .map((Object? item) => Workout.fromJson(item as Map<String, Object?>))
          .toList();
      final int nowMs = (argAt(args, 1) as num).toInt();
      final RecoveryOptions? opts = hasArg(args, 2) && argAt(args, 2) != null
          ? RecoveryOptions.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(recovery.strengthOf(workouts, nowMs, opts: opts));
    },
    'recovery.fatiguedMuscles': (List<Object?> args) {
      final List<Object?> rawWorkouts = jsonListArg(args, 0);
      final List<Workout> workouts = rawWorkouts
          .map((Object? item) => Workout.fromJson(item as Map<String, Object?>))
          .toList();
      final int nowMs = (argAt(args, 1) as num).toInt();
      final RecoveryOptions? opts = hasArg(args, 2) && argAt(args, 2) != null
          ? RecoveryOptions.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(recovery.fatiguedMuscles(workouts, nowMs, opts: opts));
    },
    'recovery.detrainedMuscles': (List<Object?> args) {
      final List<Object?> rawWorkouts = jsonListArg(args, 0);
      final List<Workout> workouts = rawWorkouts
          .map((Object? item) => Workout.fromJson(item as Map<String, Object?>))
          .toList();
      final int nowMs = (argAt(args, 1) as num).toInt();
      final RecoveryOptions? opts = hasArg(args, 2) && argAt(args, 2) != null
          ? RecoveryOptions.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(recovery.detrainedMuscles(workouts, nowMs, opts: opts));
    },
  };
}
