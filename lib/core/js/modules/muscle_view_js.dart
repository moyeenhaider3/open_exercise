// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `muscle-view-shim.js` functions and constants.
///
/// Handles muscle balance, fatigue view, strength view, muscle explorer indexing,
/// and absolute shading thresholds (JS-04).
library;

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/muscle_models.dart';

final class MuscleViewJs {
  const MuscleViewJs(this._engine);

  final JsEngineService _engine;

  /// Muscle balance numbers for the given window and hard-set toggle.
  /// Source: Stats.jsx:124-143 via muscle-view-shim.js.
  MuscleBalanceView muscleBalance(
    GymState s, {
    required int win,
    required bool hard,
    required int nowMs,
    required String todayIso,
  }) {
    final Object? res = _engine.call('muscleView.muscleBalance', <Object?>[
      s.toJson(),
      win,
      hard,
      nowMs,
      todayIso,
    ]);
    return MuscleBalanceView.fromJson(jsMap(res, 'muscleView.muscleBalance'));
  }

  /// Fatigue view state and absolute shade levels.
  /// Source: Stats.jsx:114-118 via muscle-view-shim.js.
  FatigueView fatigueView(GymState s, int nowMs) {
    final Object? res = _engine.call('muscleView.fatigueView', <Object?>[
      s.toJson(),
      nowMs,
    ]);
    return FatigueView.fromJson(jsMap(res, 'muscleView.fatigueView'));
  }

  /// Strength view state, absolute shade levels, detrained muscles and exercise history.
  /// Source: Stats.jsx:115, 134-138 via muscle-view-shim.js.
  StrengthView strengthView(GymState s, int nowMs, String? sel) {
    final Object? res = _engine.call('muscleView.strengthView', <Object?>[
      s.toJson(),
      nowMs,
      sel,
    ]);
    return StrengthView.fromJson(jsMap(res, 'muscleView.strengthView'));
  }

  /// Map from exercise ID to its trained muscles snapshot.
  /// Source: MuscleExplorer.jsx:34-37 via muscle-view-shim.js.
  Map<String, Map<String, double>> muscleIndex(GymState s, {List<String>? ids}) {
    final Object? res = _engine.call('muscleView.muscleIndex', <Object?>[
      s.toJson(),
      ids ?? jsUndefined,
    ]);
    final Map<String, Object?> raw = jsMap(res, 'muscleView.muscleIndex');
    final Map<String, Map<String, double>> result = <String, Map<String, double>>{};
    for (final MapEntry<String, Object?> entry in raw.entries) {
      result[entry.key] = jsDoubleMap(entry.value, 'muscleView.muscleIndex["${entry.key}"]');
    }
    return result;
  }

  /// Ordered threshold rules for fatigue shading bands.
  List<ThresholdRule> get fatigueLevels {
    final Object? res = _engine.read('muscleView.FATIGUE_LEVELS');
    return jsListOf<ThresholdRule>(res, 'muscleView.FATIGUE_LEVELS', ThresholdRule.fromJson);
  }

  /// Ordered threshold rules for strength shading bands.
  List<ThresholdRule> get strengthLevels {
    final Object? res = _engine.read('muscleView.STRENGTH_LEVELS');
    return jsListOf<ThresholdRule>(res, 'muscleView.STRENGTH_LEVELS', ThresholdRule.fromJson);
  }
}

extension MuscleViewJsAccess on JsEngineService {
  MuscleViewJs get muscleView => MuscleViewJs(this);
}
