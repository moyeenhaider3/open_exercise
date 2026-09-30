// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/models/muscle_models.dart';
import 'package:open_exercise/core/js/modules/muscle_view_js.dart';
import 'package:open_exercise/core/js/modules/muscles_js.dart';
import 'package:open_exercise/core/js/modules/recovery_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/routine.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> phase4Dispatch(JsEngineService engine) {
  final MusclesJs muscles = engine.muscles;
  final RecoveryJs recovery = engine.recovery;
  final MuscleViewJs muscleView = engine.muscleView;

  return <String, ParityCall>{
    'muscles.musclesOf': (List<Object?> args) {
      final Map<String, Object?> ex = jsonMapArg(args, 0);
      return toPlainJson(muscles.musclesOf(ex));
    },
    'muscles.loadOf': (List<Object?> args) {
      final List<Object?> raw = jsonListArg(args, 0);
      final List<Map<String, Object?>> items = raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => m.cast<String, Object?>())
          .toList();
      return toPlainJson(muscles.loadOf(items));
    },
    'muscles.loadOfWorkouts': (List<Object?> args) {
      final List<Object?> raw = jsonListArg(args, 0);
      final List<Workout> workouts = raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => Workout.fromJson(Map<String, Object?>.from(m)))
          .toList();
      return toPlainJson(muscles.loadOfWorkouts(workouts));
    },
    'muscles.loadOfActive': (List<Object?> args) {
      final Workout active = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(muscles.loadOfActive(active));
    },
    'muscles.loadOfRoutine': (List<Object?> args) {
      final Routine routine = Routine.fromJson(jsonMapArg(args, 0));
      return toPlainJson(muscles.loadOfRoutine(routine));
    },
    'muscles.levelsOf': (List<Object?> args) {
      final Map<String, Object?> rawLoad = jsonMapArg(args, 0);
      final Map<String, num> load = rawLoad.map(
        (String k, Object? v) => MapEntry<String, num>(k, v as num),
      );
      List<ThresholdRule>? thresholds;
      if (hasArg(args, 1) && !isUndefinedMarker(argAt(args, 1)) && argAt(args, 1) is List) {
        thresholds = (argAt(args, 1) as List)
            .whereType<Map<Object?, Object?>>()
            .map((Map<Object?, Object?> m) => ThresholdRule.fromJson(m.cast<String, Object?>()))
            .toList();
      }
      return toPlainJson(muscles.levelsOf(load, thresholds: thresholds));
    },
    'muscles.rankOf': (List<Object?> args) {
      final Map<String, Object?> rawLoad = jsonMapArg(args, 0);
      final Map<String, num> load = rawLoad.map(
        (String k, Object? v) => MapEntry<String, num>(k, v as num),
      );
      return toPlainJson(muscles.rankOf(load).toJson());
    },
    'muscles.muscleBalanceWindow': (List<Object?> args) {
      final List<Object?> raw = jsonListArg(args, 0);
      final List<Workout> workouts = raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => Workout.fromJson(Map<String, Object?>.from(m)))
          .toList();
      final int win = (argAt(args, 1) as num).toInt();
      final int nowMs = (argAt(args, 2) as num).toInt();
      final String todayIso = argAt(args, 3) as String;
      final int weekStart = (argAt(args, 4) as num).toInt();
      final List<Workout> res = muscles.muscleBalanceWindow(
        workouts,
        win,
        nowMs: nowMs,
        todayIso: todayIso,
        weekStart: weekStart,
      );
      return toPlainJson(res.map((Workout w) => w.toJson()).toList());
    },
    'recoveryView.fatigueStateOf': (List<Object?> args) {
      final Object? rawVal = hasArg(args, 0) ? argAt(args, 0) : null;
      final num? value = (rawVal != null && !isUndefinedMarker(rawVal) && rawVal is num)
          ? rawVal
          : null;
      return toPlainJson(recovery.fatigueStateOf(value));
    },
    'muscleView.muscleBalance': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int win = (argAt(args, 1) as num).toInt();
      final bool hard = argAt(args, 2) as bool;
      final int nowMs = (argAt(args, 3) as num).toInt();
      final String todayIso = argAt(args, 4) as String;
      return toPlainJson(muscleView.muscleBalance(
        s,
        win: win,
        hard: hard,
        nowMs: nowMs,
        todayIso: todayIso,
      ).toJson());
    },
    'muscleView.fatigueView': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int nowMs = (argAt(args, 1) as num).toInt();
      return toPlainJson(muscleView.fatigueView(s, nowMs).toJson());
    },
    'muscleView.strengthView': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final int nowMs = (argAt(args, 1) as num).toInt();
      final Object? rawSel = hasArg(args, 2) ? argAt(args, 2) : null;
      final String? sel = (rawSel != null && !isUndefinedMarker(rawSel) && rawSel is String)
          ? rawSel
          : null;
      return toPlainJson(muscleView.strengthView(s, nowMs, sel).toJson());
    },
    'muscleView.muscleIndex': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      List<String>? ids;
      if (hasArg(args, 1) && !isUndefinedMarker(argAt(args, 1)) && argAt(args, 1) is List) {
        ids = (argAt(args, 1) as List).cast<String>();
      }
      final Map<String, Map<String, double>> res = muscleView.muscleIndex(s, ids: ids);
      return toPlainJson(res);
    },
  };
}
