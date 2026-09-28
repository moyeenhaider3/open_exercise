// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `progression.js` module.
///
/// Automatic progression, deload calculations, stall counting, and prescription
/// generation delegate exclusively to openGym's original JavaScript implementation (JS-04).
library;

import '../../models/gym_state.dart';
import '../../models/routine.dart';
import '../../models/set_entry.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/progression_models.dart';

final class ProgressionJs {
  const ProgressionJs(this._engine);

  final JsEngineService _engine;

  /// True if [value] is a valid numeric deload factor between DELOAD_FACTOR_MIN and DELOAD_FACTOR_MAX.
  bool isValidDeloadFactor(Object? value) {
    final Object? result = _engine.call('progression.isValidDeloadFactor', <Object?>[value]);
    return jsBool(result, 'progression.isValidDeloadFactor');
  }

  /// Configured deload factor for an exercise, falling back to DELOAD_FACTOR.
  double deloadFactorOf(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'progression.deloadFactorOf',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsDouble(result, 'progression.deloadFactorOf');
  }

  /// Calculates Epley estimated 1RM for progression purposes.
  double? epley1RM(num? weight, num? reps) {
    final Object? result = _engine.call('progression.epley1RM', <Object?>[weight, reps]);
    return jsDoubleOrNull(result, 'progression.epley1RM');
  }

  /// Calculates the target 1RM for a deload session.
  double? deloadTarget1RM(num? weight, num? reps, {num? factor, bool? perSide}) {
    final Object? result = _engine.call(
      'progression.deloadTarget1RM',
      <Object?>[
        weight,
        reps,
        factor ?? jsUndefined,
        perSide ?? jsUndefined,
      ],
    );
    return jsDoubleOrNull(result, 'progression.deloadTarget1RM');
  }

  /// Default weight increment based on exercise anatomy and unit.
  double defaultIncrement(String? exId, String? unit) {
    final Object? result = _engine.call(
      'progression.defaultIncrement',
      <Object?>[exId, unit],
    );
    return jsDouble(result, 'progression.defaultIncrement');
  }

  /// Weight increment for an exercise configuration in the given unit.
  double weightIncrement(RoutineExercise? cfg, String? unit) {
    final Object? result = _engine.call(
      'progression.weightIncrement',
      <Object?>[cfg?.toJson() ?? jsUndefined, unit],
    );
    return jsDouble(result, 'progression.weightIncrement');
  }

  /// Resolves the progression policy in force ('off', 'linear', 'greyskull', 'double', 'time').
  String policyFor(RoutineExercise? cfg, Routine? routine, String? mode) {
    final Object? result = _engine.call(
      'progression.policyFor',
      <Object?>[
        cfg?.toJson() ?? jsUndefined,
        routine?.toJson() ?? jsUndefined,
        mode ?? jsUndefined,
      ],
    );
    return jsString(result, 'progression.policyFor');
  }

  /// Snaps a weight value to a loadable multiple of the increment step.
  double snapWeight(num v, num? step) {
    final Object? result = _engine.call('progression.snapWeight', <Object?>[v, step]);
    return jsDouble(result, 'progression.snapWeight');
  }

  /// Adds a step to a weight, preserving grid alignment when already on the grid.
  double addStep(num? w, num step, num? inc) {
    final Object? result = _engine.call('progression.addStep', <Object?>[w, step, inc]);
    return jsDouble(result, 'progression.addStep');
  }

  /// Steps a weight value up or down by direction (+1 or -1) * step.
  double stepWeight(num? value, num step, num direction) {
    final Object? result = _engine.call('progression.stepWeight', <Object?>[value, step, direction]);
    return jsDouble(result, 'progression.stepWeight');
  }

  /// Backs off a weight by a deload factor to a loadable grid step.
  double deloadTo(num cur, num step, {num? factor}) {
    final Object? result = _engine.call(
      'progression.deloadTo',
      <Object?>[cur, step, factor ?? jsUndefined],
    );
    return jsDouble(result, 'progression.deloadTo');
  }

  /// Selects a bounded weight and reps candidate pair for an Epley deload target.
  DeloadCandidate? selectDeloadCandidate(DeloadCandidateQuery q) {
    final Object? result = _engine.call('progression.selectDeloadCandidate', <Object?>[q.toJson()]);
    if (result == null) return null;
    return DeloadCandidate.fromJson(jsMap(result, 'progression.selectDeloadCandidate'));
  }

  /// Reduces a completed workout entry to its progression-scoring summary.
  SessionSummary? readSession(WorkoutEntry entry, [Object? fallback]) {
    final Object? fallbackJson = fallback is JsonEncodable ? fallback.toJson() : fallback;
    final Object? result = _engine.call(
      'progression.readSession',
      <Object?>[entry.toJson(), fallbackJson ?? jsUndefined],
    );
    if (result == null) return null;
    return SessionSummary.fromJson(jsMap(result, 'progression.readSession'));
  }

  /// Chronological list of scored past sessions for an exercise.
  List<SessionSummary> sessionsFor(GymState s, String exId, [Object? fallback]) {
    final Object? fallbackJson = fallback is JsonEncodable ? fallback.toJson() : fallback;
    final Object? result = _engine.call(
      'progression.sessionsFor',
      <Object?>[s.toJson(), exId, fallbackJson ?? jsUndefined],
    );
    return jsListOf<SessionSummary>(
      result,
      'progression.sessionsFor',
      SessionSummary.fromJson,
    );
  }

  /// Counts consecutive stalled sessions leading up to the most recent.
  int stallCount(List<SessionSummary> sessions, [String? policy]) {
    final Object? result = _engine.call(
      'progression.stallCount',
      <Object?>[
        sessions.map((SessionSummary s) => s.toJson()).toList(),
        policy ?? jsUndefined,
      ],
    );
    return jsInt(result, 'progression.stallCount');
  }

  /// Generates the next recommended prescription for an exercise.
  Prescription nextPrescription(GymState s, RoutineExercise cfg, Routine? routine) {
    final Object? result = _engine.call(
      'progression.nextPrescription',
      <Object?>[s.toJson(), cfg.toJson(), routine?.toJson() ?? jsUndefined],
    );
    return Prescription.fromJson(jsMap(result, 'progression.nextPrescription'));
  }

  /// Applies a progression prescription to a set list.
  List<SetEntry> applyPrescription(List<SetEntry> sets, Prescription? p, {num? step}) {
    final Object? result = _engine.call(
      'progression.applyPrescription',
      <Object?>[
        sets.map((SetEntry s) => s.toJson()).toList(),
        p?.toJson() ?? jsUndefined,
        step ?? jsUndefined,
      ],
    );
    return jsListOf<SetEntry>(
      result,
      'progression.applyPrescription',
      SetEntry.fromJson,
    );
  }

  /// Available progression policies ('off', 'linear', 'greyskull', 'double', 'time').
  List<String> get policies => jsStringList(_engine.read('progression.POLICIES'), 'progression.POLICIES');

  /// Mapping of exercise modes to sensible progression policies.
  Map<String, List<String>> get policiesFor {
    final Map<String, Object?> raw =
        jsMap(_engine.read('progression.POLICIES_FOR'), 'progression.POLICIES_FOR');
    return raw.map(
      (String k, Object? v) =>
          MapEntry<String, List<String>>(k, jsStringList(v, 'progression.POLICIES_FOR["$k"]')),
    );
  }

  /// Default deload factor (0.9).
  double get deloadFactor => jsDouble(_engine.read('progression.DELOAD_FACTOR'), 'progression.DELOAD_FACTOR');

  /// Number of stalled sessions before triggering a deload per policy.
  Map<String, int> get deloadAfter {
    final Map<String, Object?> raw =
        jsMap(_engine.read('progression.DELOAD_AFTER'), 'progression.DELOAD_AFTER');
    return raw.map(
      (String k, Object? v) =>
          MapEntry<String, int>(k, jsInt(v, 'progression.DELOAD_AFTER["$k"]')),
    );
  }

  /// Minimum allowed deload factor.
  double get deloadFactorMin =>
      jsDouble(_engine.read('progression.DELOAD_FACTOR_MIN'), 'progression.DELOAD_FACTOR_MIN');

  /// Maximum allowed deload factor.
  double get deloadFactorMax =>
      jsDouble(_engine.read('progression.DELOAD_FACTOR_MAX'), 'progression.DELOAD_FACTOR_MAX');

  /// Default second increment for timed exercises (5).
  int get defaultSecIncrement =>
      jsInt(_engine.read('progression.DEFAULT_SEC_INCREMENT'), 'progression.DEFAULT_SEC_INCREMENT');

  /// Maximum number of sets to grow bodyweight progression to (6).
  int get maxBwSets => jsInt(_engine.read('progression.MAX_BW_SETS'), 'progression.MAX_BW_SETS');
}

extension ProgressionJsAccess on JsEngineService {
  ProgressionJs get progression => ProgressionJs(this);
}
