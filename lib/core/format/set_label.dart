// SPDX-License-Identifier: AGPL-3.0-or-later

/// Presentation label and summary helpers for sets and exercise configurations.
///
/// Ported from openGym history.js lines 50-160 (fmtSec, effortTail, setLabel, exLine).
/// String assembly and formatting only — presentation, not domain math, JS-04 does not apply.
/// All classifications (mode, bodyweight, per-side, side sets, effort scale) are bridged.
library;

import '../i18n/t.dart';
import '../js/js_engine_service.dart';
import '../js/models/history_models.dart';
import '../js/modules/history_js.dart';
import '../js/modules/workout_model_js.dart';
import '../models/routine.dart';
import '../models/set_entry.dart';
import 'format.dart';

// Ported from ../openGym/frontend/src/lib/history.js:58 (fmtSec)
String fmtSec(num? sec) {
  final int n = (sec ?? 0).round().clamp(0, 1 << 31);
  return '${n ~/ 60}:${(n % 60).toString().padLeft(2, '0')}';
}

// Ported from ../openGym/frontend/src/lib/history.js:101 (effortTail)
String _effortTail(JsEngineService engine, SetEntry s) {
  final Map<String, EffortScale> scales = engine.history.effort;
  if (s.rir != null && scales.containsKey('rir')) {
    return ' (${scales['rir']!.hd} ${fmtNum(s.rir!)})';
  }
  if (s.rpe != null && scales.containsKey('rpe')) {
    return ' (${scales['rpe']!.hd} ${fmtNum(s.rpe!)})';
  }
  return '';
}

num? _extraNum(SetEntry s, String key) {
  final Object? v = s.extra[key];
  return v is num ? v : null;
}

num? _cfgNum(RoutineExercise cfg, String key) {
  final Object? v = cfg.extra[key];
  return v is num ? v : null;
}

// Ported from ../openGym/frontend/src/lib/history.js:108 (setLabel)
String setLabel(
  JsEngineService engine,
  String id,
  SetEntry s,
  RoutineExercise? cfg,
) {
  final RoutineExercise c = cfg ?? RoutineExercise(id: id);
  String mode = engine.history.modeOf(c);

  final num minVal = _extraNum(s, 'min') ?? 0;
  final num speedVal = _extraNum(s, 'speed') ?? 0;
  final num secVal = _extraNum(s, 'sec') ?? 0;

  // A set saved by an older build carries no target with it; the set's own fields still say what
  // it was — seconds for a timed set, minutes for cardio — so those are not read back as "0 reps".
  if (cfg == null && !(s.r != null && s.r! > 0)) {
    if (minVal > 0 || speedVal > 0) {
      mode = 'cardio';
    } else if (secVal > 0) {
      mode = 'time';
    }
  }

  if (mode == 'cardio') {
    return '${minVal > 0 ? minVal : 0} min @ ${fmtNum(speedVal)} km/h';
  }
  if (mode == 'time') {
    final String base = fmtSec(secVal);
    return (s.w != null && s.w! > 0) ? '$base · ${fmtNum(s.w!)}' : base;
  }

  final RoutineExercise targetCfg = (c.id != null && c.id!.isNotEmpty)
      ? c
      : c.copyWith(id: id);
  final bool bw = engine.history.isBw(targetCfg);

  // One side's "weight×reps" (or bodyweight "reps" / "+belt × reps"), the same shape a whole
  // straight set reads as — reused for each side of a unilateral set below.
  String oneSide(SetEntry side) {
    final num reps = side.r ?? 0;
    final num weight = side.w ?? 0;
    if (bw) {
      final String prefix = weight > 0 ? '+${fmtNum(weight)} × ' : '';
      return '$prefix$reps';
    }
    return '${fmtNum(weight)}×$reps';
  }

  // A unilateral set logged per side (issue #60) reads "L 15×8 · R 15×7" — the asymmetry is the
  // whole point, so both sides are shown rather than a single combined total.
  if (engine.workoutModel.isSideSet(s)) {
    final SetEntry left = s.sides?.left ?? const SetEntry();
    final SetEntry right = s.sides?.right ?? const SetEntry();
    final bool partial = (left.done == true) != (right.done == true);

    final String leftLabel = (partial && left.done != true)
        ? '—'
        : '${oneSide(left)}${_effortTail(engine, left)}';
    final String rightLabel = (partial && right.done != true)
        ? '—'
        : '${oneSide(right)}${_effortTail(engine, right)}';

    return '${t('L')} $leftLabel · ${t('R')} $rightLabel';
  }

  // Bodyweight reads as what you did — "12", or "+10 × 12" once there is a belt involved —
  // rather than "0×12", which says a set was performed with no weight and means nothing.
  return '${oneSide(s)}${_effortTail(engine, s)}';
}

// Ported from ../openGym/frontend/src/lib/history.js:140 (exLine)
String exLine(JsEngineService engine, RoutineExercise cfg, String unit) {
  final String mode = engine.history.modeOf(cfg);
  final int n = cfg.sets?.toInt() ?? 1;
  final num? weight = cfg.weight;
  final bool hasWeight = weight != null && weight != 0;

  // Added weight reads as added: "+10 kg" on a dip belt, "60 kg" on a barbell.
  final String load = hasWeight
      ? ' · ${engine.history.isBw(cfg) ? '+' : ''}${fmtNum(weight)} $unit'
      : '';

  if (mode == 'cardio') {
    final num minVal = _cfgNum(cfg, 'min') ?? 20;
    final num speedVal = _cfgNum(cfg, 'speed') ?? 8;
    return '$n × $minVal min @ ${fmtNum(speedVal)} km/h';
  }
  if (mode == 'time') {
    final num secVal = _cfgNum(cfg, 'sec') ?? 45;
    return '$n × ${fmtSec(secVal)}$load';
  }

  // This is the line with room for it, so the split is spelled out: "3 × 16 · 8/side".
  final String split = engine.history.isPerSide(cfg)
      ? ' · ${t('{0}/side', <Object?>[fmtNum(engine.history.sideReps(cfg.reps))])}'
      : '';

  return '$n × ${cfg.reps ?? 0}$load$split';
}
