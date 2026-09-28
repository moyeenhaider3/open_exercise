// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/json_passthrough.dart';
import '../js_codec.dart';

/// Next workout prescription for an exercise calculated by openGym's progression policy.
class Prescription extends Equatable implements JsonEncodable {
  const Prescription({
    this.policy,
    this.kind,
    this.weight,
    this.reps,
    this.sec,
    this.sets,
    this.target1RM,
    this.deloadFactor,
    this.why,
    this.extra = const <String, Object?>{},
  });

  final String? policy;
  final String? kind;
  final num? weight;
  final num? reps;
  final num? sec;
  final num? sets;
  final double? target1RM;
  final double? deloadFactor;
  final List<Object?>? why;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'policy',
    'kind',
    'weight',
    'reps',
    'sec',
    'sets',
    'target1RM',
    'deloadFactor',
    'why',
  };

  factory Prescription.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return Prescription(
      policy: reader.string('policy'),
      kind: reader.string('kind'),
      weight: reader.number('weight'),
      reps: reader.number('reps'),
      sec: reader.number('sec'),
      sets: reader.number('sets'),
      target1RM: reader.number('target1RM')?.toDouble(),
      deloadFactor: reader.number('deloadFactor')?.toDouble(),
      why: reader.list('why'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'policy': policy,
        'kind': kind,
        'weight': weight,
        'reps': reps,
        'sec': sec,
        'sets': sets,
        'target1RM': target1RM,
        'deloadFactor': deloadFactor,
        'why': why,
      });

  @override
  List<Object?> get props =>
      <Object?>[policy, kind, weight, reps, sec, sets, target1RM, deloadFactor, why, extra];
}

/// Query parameters for selecting an Epley deload candidate.
class DeloadCandidateQuery extends Equatable implements JsonEncodable {
  const DeloadCandidateQuery({
    this.currentWeight,
    this.targetWeight,
    this.targetReps,
    this.step,
    this.factor,
    this.reps,
    this.repsMin,
    this.perSide,
    this.extra = const <String, Object?>{},
  });

  final num? currentWeight;
  final num? targetWeight;
  final num? targetReps;
  final num? step;
  final num? factor;
  final num? reps;
  final num? repsMin;
  final bool? perSide;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'currentWeight',
    'targetWeight',
    'targetReps',
    'step',
    'factor',
    'reps',
    'repsMin',
    'perSide',
  };

  factory DeloadCandidateQuery.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return DeloadCandidateQuery(
      currentWeight: reader.number('currentWeight'),
      targetWeight: reader.number('targetWeight'),
      targetReps: reader.number('targetReps'),
      step: reader.number('step'),
      factor: reader.number('factor'),
      reps: reader.number('reps'),
      repsMin: reader.number('repsMin'),
      perSide: reader.boolean('perSide'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'currentWeight': currentWeight,
        'targetWeight': targetWeight,
        'targetReps': targetReps,
        'step': step,
        'factor': factor,
        'reps': reps,
        'repsMin': repsMin,
        'perSide': perSide,
      });

  @override
  List<Object?> get props => <Object?>[
        currentWeight,
        targetWeight,
        targetReps,
        step,
        factor,
        reps,
        repsMin,
        perSide,
        extra,
      ];
}

/// A candidate weight/reps combination for a deload session.
class DeloadCandidate extends Equatable implements JsonEncodable {
  const DeloadCandidate({
    this.weight,
    this.reps,
    this.epley,
    this.error,
    this.repChange,
    this.fallback,
    this.target1RM,
    this.factor,
    this.upper,
    this.bottom,
    this.extra = const <String, Object?>{},
  });

  final num? weight;
  final num? reps;
  final double? epley;
  final double? error;
  final num? repChange;
  final bool? fallback;
  final double? target1RM;
  final double? factor;
  final num? upper;
  final num? bottom;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'weight',
    'reps',
    'epley',
    'error',
    'repChange',
    'fallback',
    'target1RM',
    'factor',
    'upper',
    'bottom',
  };

  factory DeloadCandidate.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return DeloadCandidate(
      weight: reader.number('weight'),
      reps: reader.number('reps'),
      epley: reader.number('epley')?.toDouble(),
      error: reader.number('error')?.toDouble(),
      repChange: reader.number('repChange'),
      fallback: reader.boolean('fallback'),
      target1RM: reader.number('target1RM')?.toDouble(),
      factor: reader.number('factor')?.toDouble(),
      upper: reader.number('upper'),
      bottom: reader.number('bottom'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'weight': weight,
        'reps': reps,
        'epley': epley,
        'error': error,
        'repChange': repChange,
        'fallback': fallback,
        'target1RM': target1RM,
        'factor': factor,
        'upper': upper,
        'bottom': bottom,
      });

  @override
  List<Object?> get props => <Object?>[
        weight,
        reps,
        epley,
        error,
        repChange,
        fallback,
        target1RM,
        factor,
        upper,
        bottom,
        extra,
      ];
}

/// Reduction of one finished workout entry for progression evaluation.
class SessionSummary extends Equatable implements JsonEncodable {
  const SessionSummary({
    this.mode,
    this.target,
    this.goal,
    this.held,
    this.reps,
    this.weight,
    this.count,
    this.low,
    this.amrap,
    this.best,
    this.ok,
    this.d,
    this.extra = const <String, Object?>{},
  });

  final String? mode;
  final Map<String, Object?>? target;
  final num? goal;
  final List<num>? held;
  final List<num>? reps;
  final num? weight;
  final int? count;
  final num? low;
  final num? amrap;
  final num? best;
  final bool? ok;
  final String? d;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'mode',
    'target',
    'goal',
    'held',
    'reps',
    'weight',
    'count',
    'low',
    'amrap',
    'best',
    'ok',
    'd',
  };

  factory SessionSummary.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    final List<Object?>? rawHeld = reader.list('held');
    final List<num>? heldList = rawHeld?.map((Object? x) => x as num).toList();
    final List<Object?>? rawReps = reader.list('reps');
    final List<num>? repsList = rawReps?.map((Object? x) => x as num).toList();

    return SessionSummary(
      mode: reader.string('mode'),
      target: reader.map('target'),
      goal: reader.number('goal'),
      held: heldList,
      reps: repsList,
      weight: reader.number('weight'),
      count: reader.integer('count'),
      low: reader.number('low'),
      amrap: reader.number('amrap'),
      best: reader.number('best'),
      ok: reader.boolean('ok'),
      d: reader.string('d'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'mode': mode,
        'target': target,
        'goal': goal,
        'held': held,
        'reps': reps,
        'weight': weight,
        'count': count,
        'low': low,
        'amrap': amrap,
        'best': best,
        'ok': ok,
        'd': d,
      });

  @override
  List<Object?> get props => <Object?>[
        mode,
        target,
        goal,
        held,
        reps,
        weight,
        count,
        low,
        amrap,
        best,
        ok,
        d,
        extra,
      ];
}
