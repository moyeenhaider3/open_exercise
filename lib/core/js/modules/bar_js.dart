// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `bar.js` module.
///
/// Bar detection, default equipment weights, override checks, and per-side
/// plate calculations delegate directly to openGym's JavaScript library (JS-04).
library;

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

final class BarJs {
  const BarJs(this._engine);

  final JsEngineService _engine;

  Object? _validateExOrId(Object? exOrId) {
    if (exOrId == null || exOrId is String || exOrId is Map<String, Object?>) {
      return exOrId;
    }
    throw ArgumentError.value(
      exOrId,
      'exOrId',
      'Expected String (exercise id), Map<String, Object?> (exercise object), or null',
    );
  }

  /// Whether an exercise (exercise object or exercise ID) is done with a bar.
  bool usesBar(Object? exOrId) {
    final Object? validEx = _validateExOrId(exOrId);
    final Object? result = _engine.call('bar.usesBar', <Object?>[validEx]);
    return jsBool(result, 'bar.usesBar');
  }

  /// Default bar weight for equipment type [eq] in unit [unit] ('kg' or 'lb').
  double? defaultBarWeight(String eq, String unit) {
    final Object? result = _engine.call('bar.defaultBarWeight', <Object?>[eq, unit]);
    return jsDoubleOrNull(result, 'bar.defaultBarWeight');
  }

  /// True when the user explicitly set "no bar" (stored as 0) for [exId].
  bool isNoBar(GymState s, String exId) {
    final Object? result = _engine.call('bar.isNoBar', <Object?>[s.toJson(), exId]);
    return jsBool(result, 'bar.isNoBar');
  }

  /// True when the user has set their own bar weight for [exId] (including 0).
  bool hasBarOverride(GymState s, String exId) {
    final Object? result = _engine.call('bar.hasBarOverride', <Object?>[s.toJson(), exId]);
    return jsBool(result, 'bar.hasBarOverride');
  }

  /// Effective bar weight for an exercise in profile unit [s.unit].
  double? barWeightFor(GymState s, Object? exOrId) {
    final Object? validEx = _validateExOrId(exOrId);
    final Object? result = _engine.call('bar.barWeightFor', <Object?>[s.toJson(), validEx]);
    return jsDoubleOrNull(result, 'bar.barWeightFor');
  }

  /// Plates per side: half of the remaining weight after subtracting the bar.
  ///
  /// Returns null if total <= bar, total <= 0, bar < 0, or missing/non-finite.
  double? plateSplit(num? total, num? bar) {
    final Object? result = _engine.call('bar.plateSplit', <Object?>[total, bar]);
    return jsDoubleOrNull(result, 'bar.plateSplit');
  }

  /// Default bar weights per equipment type for a kg profile.
  Map<String, double> get defaultBarKg =>
      jsDoubleMap(_engine.read('bar.DEFAULT_BAR_KG'), 'bar.DEFAULT_BAR_KG');

  /// Default bar weights per equipment type for a lb profile.
  Map<String, double> get defaultBarLb =>
      jsDoubleMap(_engine.read('bar.DEFAULT_BAR_LB'), 'bar.DEFAULT_BAR_LB');
}

extension BarJsAccess on JsEngineService {
  BarJs get bar => BarJs(this);
}
