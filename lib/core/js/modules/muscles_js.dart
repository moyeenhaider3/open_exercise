// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/routine.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/muscle_models.dart';

/// Facade for openGym `muscles.js` functions and metadata.
final class MusclesJs {
  const MusclesJs(this._engine);

  final JsEngineService _engine;

  List<String> get muscles => jsStringList(_engine.read('muscles.MUSCLES'), 'muscles.MUSCLES');

  /// List of inert body parts (hair, head, neck, hands, feet, knees, ankles).
  /// Source: muscles.js lines 16-17.
  List<String> get inert => jsStringList(_engine.read('muscles.INERT'), 'muscles.INERT');

  Map<String, String> get muscleName {
    final Map<String, Object?>? raw = jsMapOrNull(_engine.read('muscles.MUSCLE_NAME'), 'muscles.MUSCLE_NAME');
    if (raw == null) return const <String, String>{};
    return raw.map((String k, Object? v) => MapEntry<String, String>(k, v?.toString() ?? ''));
  }

  List<String> inMuscleOrder(List<String> list) {
    final Object? res = _engine.call('muscles.inMuscleOrder', <Object?>[list]);
    return jsStringList(res, 'muscles.inMuscleOrder');
  }

  bool hasExplicitMuscleMetadata(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.hasExplicitMuscleMetadata', <Object?>[ex]);
    return jsBool(res, 'muscles.hasExplicitMuscleMetadata');
  }

  List<String> normalizeMuscleGroups(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.normalizeMuscleGroups', <Object?>[ex]);
    return jsStringList(res, 'muscles.normalizeMuscleGroups');
  }

  Map<String, Object?>? exerciseMuscleSnapshot(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.exerciseMuscleSnapshot', <Object?>[ex]);
    return jsMapOrNull(res, 'muscles.exerciseMuscleSnapshot');
  }

  /// Muscle weights for an exercise (primary 1, secondary 0.4).
  /// Source: muscles.js lines 203-241.
  Map<String, double> musclesOf(Map<String, Object?> ex) {
    final Object? res = _engine.call('muscles.musclesOf', <Object?>[ex]);
    return jsDoubleMap(res, 'muscles.musclesOf');
  }

  /// Training load per muscle from set count items.
  /// Source: muscles.js lines 249-260.
  Map<String, double> loadOf(List<Map<String, Object?>> items) {
    final Object? res = _engine.call('muscles.loadOf', <Object?>[items]);
    return jsDoubleMap(res, 'muscles.loadOf');
  }

  /// Training load for finished workouts.
  /// Source: muscles.js lines 268-270.
  Map<String, double> loadOfWorkouts(List<Workout> workouts) {
    final Object? res = _engine.call('muscles.loadOfWorkouts', <Object?>[
      workouts.map((Workout w) => w.toJson()).toList(),
      jsUndefined,
    ]);
    return jsDoubleMap(res, 'muscles.loadOfWorkouts');
  }

  /// Training load for in-progress active workout.
  /// Source: muscles.js lines 291-293.
  Map<String, double> loadOfActive(Workout active) {
    final Object? res = _engine.call('muscles.loadOfActive', <Object?>[active.toJson()]);
    return jsDoubleMap(res, 'muscles.loadOfActive');
  }

  /// Training load a routine would produce from planned set counts.
  /// Source: muscles.js lines 287-288.
  Map<String, double> loadOfRoutine(Routine routine) {
    final Object? res = _engine.call('muscles.loadOfRoutine', <Object?>[routine.toJson()]);
    return jsDoubleMap(res, 'muscles.loadOfRoutine');
  }

  /// Shading levels (0-4) per muscle, relative or by threshold rules.
  /// Source: muscles.js lines 305-327.
  Map<String, int> levelsOf(Map<String, num> load, {List<ThresholdRule>? thresholds}) {
    final Object? res = _engine.call('muscles.levelsOf', <Object?>[
      load,
      thresholds != null ? thresholds.map((ThresholdRule r) => r.toJson()).toList() : jsUndefined,
    ]);
    return jsIntMap(res, 'muscles.levelsOf');
  }

  /// Muscles ranked by load; untrained ones last in body order.
  /// Source: muscles.js lines 330-335.
  MuscleRank rankOf(Map<String, num> load) {
    final Object? res = _engine.call('muscles.rankOf', <Object?>[load]);
    return MuscleRank.fromJson(jsMap(res, 'muscles.rankOf'), 'muscles.rankOf');
  }

  /// Filters workouts into a muscle balance window (0=all, 7=this week, N=last N days).
  /// Source: muscles.js lines 278-284.
  List<Workout> muscleBalanceWindow(
    List<Workout> workouts,
    int win, {
    required int nowMs,
    required String todayIso,
    required int weekStart,
  }) {
    final Object? res = _engine.call('muscles.muscleBalanceWindow', <Object?>[
      workouts.map((Workout w) => w.toJson()).toList(),
      win,
      nowMs,
      todayIso,
      weekStart,
    ]);
    return jsListOf<Workout>(res, 'muscles.muscleBalanceWindow', Workout.fromJson);
  }
}

extension MusclesJsAccess on JsEngineService {
  MusclesJs get muscles => MusclesJs(this);
}
