// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `onerm.js` module.
///
/// All 1RM estimation math runs in JavaScript via [JsEngineService]. Rep cap
/// restrictions (REP_CAP) and warm-up exclusions are computed exclusively in
/// openGym's original JavaScript implementation (JS-04).
library;

import '../../models/gym_state.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/onerm_models.dart';

final class OnermJs {
  const OnermJs(this._engine);

  final JsEngineService _engine;

  /// Estimate a 1RM from weight [w] and reps [r], optionally using [formula].
  ///
  /// Returns null if weight <= 0, reps < 1, reps > REP_CAP, or if inputs are non-finite.
  double? estimate1RM(num w, num r, {String? formula}) {
    final Object? result = _engine.call(
      'onerm.estimate1RM',
      <Object?>[w, r, formula ?? jsUndefined],
    );
    return jsDoubleOrNull(result, 'onerm.estimate1RM');
  }

  /// Best estimate out of one workout entry's completed sets.
  OnermBestSet? bestSetOf(WorkoutEntry entry, {String? formula}) {
    final Object? result = _engine.call(
      'onerm.bestSetOf',
      <Object?>[entry.toJson(), formula ?? jsUndefined],
    );
    if (result == null) return null;
    return OnermBestSet.fromJson(jsMap(result, 'onerm.bestSetOf'));
  }

  /// One point per workout in which the exercise produced an estimate.
  List<E1rmPoint> e1rmSeries(GymState s, String exId, {String? formula}) {
    final Object? result = _engine.call(
      'onerm.e1rmSeries',
      <Object?>[s.toJson(), exId, formula ?? jsUndefined],
    );
    return jsListOf<E1rmPoint>(
      result,
      'onerm.e1rmSeries',
      E1rmPoint.fromJson,
    );
  }

  /// All-time best estimate for an exercise.
  OnermBest? best1RM(GymState s, String exId, {String? formula}) {
    final Object? result = _engine.call(
      'onerm.best1RM',
      <Object?>[s.toJson(), exId, formula ?? jsUndefined],
    );
    if (result == null) return null;
    return OnermBest.fromJson(jsMap(result, 'onerm.best1RM'));
  }

  /// Determines whether [entry] set a new all-time 1RM personal record.
  OnermRecord? is1RMRecord(GymState s, String exId, WorkoutEntry entry, {String? formula}) {
    final Object? result = _engine.call(
      'onerm.is1RMRecord',
      <Object?>[s.toJson(), exId, entry.toJson(), formula ?? jsUndefined],
    );
    if (result == null) return null;
    return OnermRecord.fromJson(jsMap(result, 'onerm.is1RMRecord'));
  }

  /// Repetition cap above which 1RM estimation is refused (default: 12).
  int get repCap => jsInt(_engine.read('onerm.REP_CAP'), 'onerm.REP_CAP');

  /// The default 1RM estimation formula name (default: 'epley').
  String get defaultFormula => jsString(_engine.read('onerm.DEFAULT_FORMULA'), 'onerm.DEFAULT_FORMULA');

  /// Names of all available 1RM formulas (e.g. 'epley', 'brzycki', 'lombardi').
  List<String> get formulas => _engine.keysOf('onerm.FORMULAS');
}

extension OnermJsAccess on JsEngineService {
  OnermJs get onerm => OnermJs(this);
}
