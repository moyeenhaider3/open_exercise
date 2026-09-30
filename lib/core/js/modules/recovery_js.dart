// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `recovery.js` module.
///
/// Per-muscle fatigue accumulation, retained strength decay, and muscle status
/// calculations delegate directly to openGym's JavaScript library (JS-04).
/// All functions require [nowMs] to be passed explicitly, ensuring deterministic
/// calculations independent of wall-clock time.
library;

import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/recovery_models.dart';

final class RecoveryJs {
  const RecoveryJs(this._engine);

  final JsEngineService _engine;

  /// Calculates exponential decay as a fraction of one half-life.
  double halfLifeDecay(num ageMs, num halfLifeMs) {
    final Object? result = _engine.call('recovery.halfLifeDecay', <Object?>[ageMs, halfLifeMs]);
    return jsDouble(result, 'recovery.halfLifeDecay');
  }

  /// Calculates current per-muscle fatigue from completed sets in the recent window.
  Map<String, double> fatigueOf(List<Workout> workouts, int nowMs, {RecoveryOptions? opts}) {
    final Object? result = _engine.call(
      'recovery.fatigueOf',
      <Object?>[
        workouts.map((Workout w) => w.toJson()).toList(),
        nowMs,
        opts?.toJson() ?? jsUndefined,
      ],
    );
    return jsDoubleMap(result, 'recovery.fatigueOf');
  }

  /// Calculates retained per-muscle strength from the latest completed stimulus in all history.
  Map<String, double> strengthOf(List<Workout> workouts, int nowMs, {RecoveryOptions? opts}) {
    final Object? result = _engine.call(
      'recovery.strengthOf',
      <Object?>[
        workouts.map((Workout w) => w.toJson()).toList(),
        nowMs,
        opts?.toJson() ?? jsUndefined,
      ],
    );
    return jsDoubleMap(result, 'recovery.strengthOf');
  }

  /// Lists muscle slugs whose fatigue value exceeds 0.5 at [nowMs].
  List<String> fatiguedMuscles(List<Workout> workouts, int nowMs, {RecoveryOptions? opts}) {
    final Object? result = _engine.call(
      'recovery.fatiguedMuscles',
      <Object?>[
        workouts.map((Workout w) => w.toJson()).toList(),
        nowMs,
        opts?.toJson() ?? jsUndefined,
      ],
    );
    return jsStringList(result, 'recovery.fatiguedMuscles');
  }

  /// Lists muscle slugs whose retained strength has fallen below full retention (1.0) at [nowMs].
  List<String> detrainedMuscles(List<Workout> workouts, int nowMs, {RecoveryOptions? opts}) {
    final Object? result = _engine.call(
      'recovery.detrainedMuscles',
      <Object?>[
        workouts.map((Workout w) => w.toJson()).toList(),
        nowMs,
        opts?.toJson() ?? jsUndefined,
      ],
    );
    return jsStringList(result, 'recovery.detrainedMuscles');
  }

  /// Default reference volume per session (intensity-weighted kg).
  double get fatigueRefVolume =>
      jsDouble(_engine.read('recovery.FATIGUE_REF_VOLUME'), 'recovery.FATIGUE_REF_VOLUME');

  /// Smoothing horizon for per-muscle reference volume.
  int get fatigueMinSessions =>
      jsInt(_engine.read('recovery.FATIGUE_MIN_SESSIONS'), 'recovery.FATIGUE_MIN_SESSIONS');

  /// Exponential half-life for fatigue stimulus in milliseconds.
  int get fatigueHalfLifeMs =>
      jsInt(_engine.read('recovery.FATIGUE_HALF_LIFE_MS'), 'recovery.FATIGUE_HALF_LIFE_MS');

  /// Period after training during which retained strength remains at full value (milliseconds).
  int get strengthFullMs =>
      jsInt(_engine.read('recovery.STRENGTH_FULL_MS'), 'recovery.STRENGTH_FULL_MS');

  /// Exponential half-life for retained strength decay (milliseconds).
  int get strengthHalfLifeMs =>
      jsInt(_engine.read('recovery.STRENGTH_HALF_LIFE_MS'), 'recovery.STRENGTH_HALF_LIFE_MS');

  /// Minimum retained-strength value for an untrained or fully detrained muscle.
  double get strengthFloor =>
      jsDouble(_engine.read('recovery.STRENGTH_FLOOR'), 'recovery.STRENGTH_FLOOR');

  /// Stable labels for fatigue status buckets ('ready', 'recovering', 'fatigued').
  Map<String, String> get fatigueStates {
    final Map<String, Object?> raw =
        jsMap(_engine.read('recovery.FATIGUE_STATES'), 'recovery.FATIGUE_STATES');
    return raw.map(
      (String k, Object? v) =>
          MapEntry<String, String>(k, jsString(v, 'recovery.FATIGUE_STATES["$k"]')),
    );
  }

  /// Stable consumer-facing label for one numeric fatigue value ('ready', 'recovering', 'fatigued').
  /// Source: recovery-view.js lines 11-17.
  String fatigueStateOf(num? value) {
    final Object? result = _engine.call(
      'recoveryView.fatigueStateOf',
      <Object?>[value ?? jsUndefined],
    );
    return jsString(result, 'recoveryView.fatigueStateOf');
  }
}

extension RecoveryJsAccess on JsEngineService {
  RecoveryJs get recovery => RecoveryJs(this);
}
