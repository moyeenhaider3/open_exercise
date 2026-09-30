// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../js_bridge_exception.dart';
import '../js_codec.dart';

/// Ordered threshold rule for absolute level bucketing (Stats.jsx:44-58).
final class ThresholdRule extends Equatable {
  const ThresholdRule({
    required this.at,
    required this.level,
    this.exclusive = false,
  });

  factory ThresholdRule.fromJson(Map<String, Object?> json, [String path = 'thresholdRule']) {
    final Object? atVal = json['at'];
    if (atVal is! num) {
      throw JsBridgeException.type(
        path: '$path.at',
        message: 'Expected num, found ${atVal?.runtimeType}: $atVal',
      );
    }
    return ThresholdRule(
      at: atVal,
      level: jsInt(json['level'], '$path.level'),
      exclusive: json['exclusive'] == true,
    );
  }

  final num at;
  final int level;
  final bool exclusive;

  Map<String, Object?> toJson() {
    final Map<String, Object?> map = <String, Object?>{
      'at': at,
      'level': level,
    };
    if (exclusive) {
      map['exclusive'] = true;
    }
    return map;
  }

  @override
  List<Object?> get props => <Object?>[at, level, exclusive];
}

/// Muscle rank lists: worked muscles hardest first, missed muscles in body order.
final class MuscleRank extends Equatable {
  const MuscleRank({
    required this.worked,
    required this.missed,
  });

  factory MuscleRank.fromJson(Map<String, Object?> json, [String path = 'muscleRank']) {
    return MuscleRank(
      worked: jsStringList(json['worked'], '$path.worked'),
      missed: jsStringList(json['missed'], '$path.missed'),
    );
  }

  final List<String> worked;
  final List<String> missed;

  Map<String, Object?> toJson() => <String, Object?>{
        'worked': worked,
        'missed': missed,
      };

  @override
  List<Object?> get props => <Object?>[worked, missed];
}

/// Top-worked muscle row with bar percentage relative to hardest-worked.
final class MuscleTopRow extends Equatable {
  const MuscleTopRow({
    required this.slug,
    required this.pct,
  });

  factory MuscleTopRow.fromJson(Map<String, Object?> json, [String path = 'top']) {
    return MuscleTopRow(
      slug: jsString(json['slug'], '$path.slug'),
      pct: jsInt(json['pct'], '$path.pct'),
    );
  }

  final String slug;
  final int pct;

  Map<String, Object?> toJson() => <String, Object?>{
        'slug': slug,
        'pct': pct,
      };

  @override
  List<Object?> get props => <Object?>[slug, pct];
}

/// Muscle balance view payload from muscleView.muscleBalance (Stats.jsx:124-143).
final class MuscleBalanceView extends Equatable {
  const MuscleBalanceView({
    required this.inWinCount,
    required this.rated,
    required this.on,
    required this.load,
    required this.levels,
    required this.worked,
    required this.missed,
    required this.top,
    required this.sets,
  });

  factory MuscleBalanceView.fromJson(Map<String, Object?> json, [String path = 'muscleBalance']) {
    return MuscleBalanceView(
      inWinCount: jsInt(json['inWinCount'], '$path.inWinCount'),
      rated: jsBool(json['rated'], '$path.rated'),
      on: jsBool(json['on'], '$path.on'),
      load: jsDoubleMap(json['load'], '$path.load'),
      levels: jsIntMap(json['levels'], '$path.levels'),
      worked: jsStringList(json['worked'], '$path.worked'),
      missed: jsStringList(json['missed'], '$path.missed'),
      top: jsListOf<MuscleTopRow>(json['top'], '$path.top', MuscleTopRow.fromJson),
      sets: jsDoubleMap(json['sets'], '$path.sets'),
    );
  }

  final int inWinCount;
  final bool rated;
  final bool on;
  final Map<String, double> load;
  final Map<String, int> levels;
  final List<String> worked;
  final List<String> missed;
  final List<MuscleTopRow> top;
  final Map<String, double> sets;

  Map<String, Object?> toJson() => <String, Object?>{
        'inWinCount': inWinCount,
        'rated': rated,
        'on': on,
        'load': load,
        'levels': levels,
        'worked': worked,
        'missed': missed,
        'top': top.map((MuscleTopRow r) => r.toJson()).toList(),
        'sets': sets,
      };

  @override
  List<Object?> get props => <Object?>[
        inWinCount,
        rated,
        on,
        load,
        levels,
        worked,
        missed,
        top,
        sets,
      ];
}

/// Fatigue view payload from muscleView.fatigueView (Stats.jsx:114-118).
final class FatigueView extends Equatable {
  const FatigueView({
    required this.fatigue,
    required this.levels,
    required this.states,
  });

  factory FatigueView.fromJson(Map<String, Object?> json, [String path = 'fatigueView']) {
    return FatigueView(
      fatigue: jsDoubleMap(json['fatigue'], '$path.fatigue'),
      levels: jsIntMap(json['levels'], '$path.levels'),
      states: jsStringMap(json['states'], '$path.states'),
    );
  }

  final Map<String, double> fatigue;
  final Map<String, int> levels;
  final Map<String, String> states;

  Map<String, Object?> toJson() => <String, Object?>{
        'fatigue': fatigue,
        'levels': levels,
        'states': states,
      };

  @override
  List<Object?> get props => <Object?>[fatigue, levels, states];
}

/// Row in the detrained list for strength view (Stats.jsx:136-138).
final class DetrainedRow extends Equatable {
  const DetrainedRow({
    required this.slug,
    required this.pct,
    required this.sets90,
    this.weeks,
  });

  factory DetrainedRow.fromJson(Map<String, Object?> json, [String path = 'detrained']) {
    return DetrainedRow(
      slug: jsString(json['slug'], '$path.slug'),
      pct: jsInt(json['pct'], '$path.pct'),
      sets90: jsDouble(json['sets90'], '$path.sets90'),
      weeks: jsIntOrNull(json['weeks'], '$path.weeks'),
    );
  }

  final String slug;
  final int pct;
  final double sets90;
  final int? weeks;

  Map<String, Object?> toJson() => <String, Object?>{
        'slug': slug,
        'pct': pct,
        'sets90': sets90,
        'weeks': weeks,
      };

  @override
  List<Object?> get props => <Object?>[slug, pct, sets90, weeks];
}

/// Per-exercise row for tapped muscle in strength view (strength-exercises.js:117-144).
final class StrengthExerciseRow extends Equatable {
  const StrengthExerciseRow({
    required this.id,
    required this.name,
    required this.weight,
    this.primary,
    required this.est,
    required this.estDate,
    required this.decay,
    required this.decayPct,
    required this.current,
  });

  factory StrengthExerciseRow.fromJson(Map<String, Object?> json, [String path = 'exercise']) {
    return StrengthExerciseRow(
      id: jsString(json['id'], '$path.id'),
      name: jsString(json['name'], '$path.name'),
      weight: jsDouble(json['weight'], '$path.weight'),
      primary: jsStringOrNull(json['primary'], '$path.primary'),
      est: jsDouble(json['est'], '$path.est'),
      estDate: jsString(json['estDate'], '$path.estDate'),
      decay: jsDouble(json['decay'], '$path.decay'),
      decayPct: jsInt(json['decayPct'], '$path.decayPct'),
      current: jsDouble(json['current'], '$path.current'),
    );
  }

  final String id;
  final String name;
  final double weight;
  final String? primary;
  final double est;
  final String estDate;
  final double decay;
  final int decayPct;
  final double current;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'weight': weight,
        'primary': primary,
        'est': est,
        'estDate': estDate,
        'decay': decay,
        'decayPct': decayPct,
        'current': current,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        weight,
        primary,
        est,
        estDate,
        decay,
        decayPct,
        current,
      ];
}

/// Strength view payload from muscleView.strengthView (Stats.jsx:115, 134-138).
final class StrengthView extends Equatable {
  const StrengthView({
    required this.strength,
    required this.levels,
    required this.strengthFloor,
    required this.detrained,
    required this.exercises,
  });

  factory StrengthView.fromJson(Map<String, Object?> json, [String path = 'strengthView']) {
    return StrengthView(
      strength: jsDoubleMap(json['strength'], '$path.strength'),
      levels: jsIntMap(json['levels'], '$path.levels'),
      strengthFloor: jsDouble(json['strengthFloor'], '$path.strengthFloor'),
      detrained: jsListOf<DetrainedRow>(json['detrained'], '$path.detrained', DetrainedRow.fromJson),
      exercises: jsListOf<StrengthExerciseRow>(json['exercises'], '$path.exercises', StrengthExerciseRow.fromJson),
    );
  }

  final Map<String, double> strength;
  final Map<String, int> levels;
  final double strengthFloor;
  final List<DetrainedRow> detrained;
  final List<StrengthExerciseRow> exercises;

  Map<String, Object?> toJson() => <String, Object?>{
        'strength': strength,
        'levels': levels,
        'strengthFloor': strengthFloor,
        'detrained': detrained.map((DetrainedRow r) => r.toJson()).toList(),
        'exercises': exercises.map((StrengthExerciseRow r) => r.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[
        strength,
        levels,
        strengthFloor,
        detrained,
        exercises,
      ];
}
