// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../../models/set_entry.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase3_models.dart';
import '../models/phase31_models.dart';

/// Facade for openGym `effort.js` functions and presets.
final class EffortJs {
  const EffortJs(this._engine);

  final JsEngineService _engine;

  // ---- existing Phase 3 methods ----

  double? rirOf(SetEntry s) {
    final Object? res = _engine.call('effort.rirOf', <Object?>[s.toJson()]);
    return jsDoubleOrNull(res, 'effort.rirOf');
  }

  double? toScale(String kind, num? rir) {
    final Object? res = _engine.call('effort.toScale', <Object?>[kind, rir ?? jsUndefined]);
    return jsDoubleOrNull(res, 'effort.toScale');
  }

  String? effortColor(num? rir) {
    final Object? res = _engine.call('effort.effortColor', <Object?>[rir ?? jsUndefined]);
    return jsStringOrNull(res, 'effort.effortColor');
  }

  List<EffortPreset> get presets {
    final List<Object?> list = jsList(_engine.read('effort.EFFORT_PRESETS'), 'effort.EFFORT_PRESETS');
    return list
        .whereType<Map<String, Object?>>()
        .map(EffortPreset.fromJson)
        .toList();
  }

  int get hardRir => jsInt(_engine.read('effort.HARD_RIR'), 'effort.HARD_RIR');

  // ---- Phase 3.1 extensions ----

  /// Returns true when the profile holds at least one rated set.
  /// Mirrors openGym `effort.js` `hasEffort(S)`.
  bool hasEffort(GymState s) {
    final Object? res = _engine.call('effort.hasEffort', <Object?>[s.toJson()]);
    return res == true;
  }

  /// Returns the display scale ('rir' or 'rpe') to use for aggregates.
  /// Mirrors openGym `effort.js` `displayScale(S)`.
  String displayScale(GymState s) {
    final Object? res = _engine.call('effort.displayScale', <Object?>[s.toJson()]);
    return jsString(res, 'effort.displayScale');
  }

  /// Returns the heading label for a given scale kind.
  /// Mirrors openGym `effort.js` `scaleName(kind)`.
  String scaleName(String kind) {
    final Object? res = _engine.call('effort.scaleName', <Object?>[kind]);
    return jsString(res, 'effort.scaleName');
  }

  /// Returns the average RIR across a list of sets, or null if none are rated.
  /// Mirrors openGym `effort.js` `avgRir(sets)`.
  double? avgRir(List<SetEntry> sets) {
    final Object? res = _engine.call('effort.avgRir', <Object?>[
      sets.map((SetEntry s) => s.toJson()).toList(),
    ]);
    return jsDoubleOrNull(res, 'effort.avgRir');
  }

  /// Returns headline effort stats over a rolling window.
  /// Use [days] = 0 for all history (no wall-clock dependency).
  /// Mirrors openGym `effort.js` `effortSummary(S, days)`.
  EffortSummary effortSummary(GymState s, int days) {
    final Object? res = _engine.call('effort.effortSummary', <Object?>[s.toJson(), days]);
    return EffortSummary.fromJson(jsMap(res, 'effort.effortSummary'));
  }

  /// Returns per-week effort entries sorted by time.
  /// Note: this function is wall-clock/TZ-dependent (startOfWeek uses local midnight);
  /// it is excluded from parity fixtures — see gen-fixtures.mjs BANNED.
  /// Mirrors openGym `effort.js` `effortWeeks(S, days)`.
  List<EffortWeek> effortWeeks(GymState s, int days) {
    final Object? res = _engine.call('effort.effortWeeks', <Object?>[s.toJson(), days]);
    final List<Object?> list = jsList(res, 'effort.effortWeeks');
    return list
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> m) => EffortWeek.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  /// Returns histogram bins (0..4+) of rated-set distribution.
  /// Mirrors openGym `effort.js` `effortHistogram(S, days)`.
  List<EffortBin> effortHistogram(GymState s, int days) {
    final Object? res = _engine.call('effort.effortHistogram', <Object?>[s.toJson(), days]);
    final List<Object?> list = jsList(res, 'effort.effortHistogram');
    return list
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> m) => EffortBin.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  /// Returns true when a set's effort is at or below the hard threshold.
  /// Mirrors openGym `effort.js` `isHardSet(s)`.
  bool isHardSet(SetEntry s) {
    final Object? res = _engine.call('effort.isHardSet', <Object?>[s.toJson()]);
    return res == true;
  }

  /// Minimum number of rated sets before the average is considered meaningful.
  /// Mirrors openGym `effort.js` `MIN_RATED`.
  int get minRated => jsInt(_engine.read('effort.MIN_RATED'), 'effort.MIN_RATED');

  /// Number of histogram buckets (excluding the tail).
  /// Mirrors openGym `effort.js` `BUCKETS`.
  int get buckets => jsInt(_engine.read('effort.BUCKETS'), 'effort.BUCKETS');
}

extension EffortJsAccess on JsEngineService {
  EffortJs get effort => EffortJs(this);
}

