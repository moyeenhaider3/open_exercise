// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'json_passthrough.dart';

/// A drop-set's weight drop, oldest first (`../openGym/frontend/src/lib/workout-model.js`
/// `dropsOf`). Passthrough-safe: unknown keys and wrong-typed/null values on `w`/`r` survive in
/// [extra].
class DropEntry extends Equatable {
  const DropEntry({this.w, this.r, this.extra = const <String, Object?>{}});

  final num? w;
  final num? r;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'w', 'r'};

  factory DropEntry.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return DropEntry(w: reader.number('w'), r: reader.number('r'), extra: reader.extra);
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'w': w, 'r': r});

  @override
  List<Object?> get props => <Object?>[w, r, extra];
}

/// A rest-pause set's short-rest burst, oldest first (`workout-model.js` `clustersOf`).
class ClusterEntry extends Equatable {
  const ClusterEntry({this.r, this.restSec, this.extra = const <String, Object?>{}});

  final num? r;
  final num? restSec;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'r', 'restSec'};

  factory ClusterEntry.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return ClusterEntry(r: reader.number('r'), restSec: reader.number('restSec'), extra: reader.extra);
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'r': r, 'restSec': restSec});

  @override
  List<Object?> get props => <Object?>[r, restSec, extra];
}

/// Per-side (unilateral) set rows, keyed `L`/`R` (`workout-model.js` `isSideSet`). Each side is
/// itself a full [SetEntry] (it can carry its own `type`/`drops`, per the fixture's
/// `db_curl_fixture` entry).
class SideSets extends Equatable {
  const SideSets({this.left, this.right, this.extra = const <String, Object?>{}});

  final SetEntry? left;
  final SetEntry? right;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'L', 'R'};

  factory SideSets.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    final Map<String, Object?>? leftMap = reader.map('L');
    final Map<String, Object?>? rightMap = reader.map('R');
    return SideSets(
      left: leftMap == null ? null : SetEntry.fromJson(leftMap),
      right: rightMap == null ? null : SetEntry.fromJson(rightMap),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'L': left?.toJson(),
        'R': right?.toJson(),
      });

  @override
  List<Object?> get props => <Object?>[left, right, extra];
}

/// A single set row (`../openGym/frontend/src/lib/workout-model.js` lines 14-160). Covers
/// straight sets, warm-ups (explicit `phase` or legacy `warmup` boolean), dropsets, rest-pause
/// sets, and per-side (unilateral) sets. Passthrough-safe: every unknown key, explicit null and
/// wrong-typed value on a known field survives `fromJson` -> `toJson` unchanged.
///
/// Phase and type resolution lives in openGym's `workout-model.js` and is reached via
/// `JsEngineService.workoutModel.phaseForSet` / `.setType` (JS-04, Phase 1 CR-02).
class SetEntry extends Equatable {
  const SetEntry({
    this.w,
    this.r,
    this.done,
    this.rir,
    this.rpe,
    this.phase,
    this.warmup,
    this.type,
    this.drops,
    this.clusters,
    this.sides,
    this.extra = const <String, Object?>{},
  });

  final num? w;
  final num? r;
  final bool? done;
  final num? rir;
  final num? rpe;
  final String? phase;
  final bool? warmup;
  final String? type;
  final List<DropEntry>? drops;
  final List<ClusterEntry>? clusters;
  final SideSets? sides;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'w', 'r', 'done', 'rir', 'rpe', 'phase', 'warmup', 'type', 'drops', 'clusters', 'sides',
  };

  factory SetEntry.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    final Map<String, Object?>? sidesMap = reader.map('sides');
    return SetEntry(
      w: reader.number('w'),
      r: reader.number('r'),
      done: reader.boolean('done'),
      rir: reader.number('rir'),
      rpe: reader.number('rpe'),
      phase: reader.string('phase'),
      warmup: reader.boolean('warmup'),
      type: reader.string('type'),
      drops: reader.objectList<DropEntry>('drops', DropEntry.fromJson),
      clusters: reader.objectList<ClusterEntry>('clusters', ClusterEntry.fromJson),
      sides: sidesMap == null ? null : SideSets.fromJson(sidesMap),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'w': w,
        'r': r,
        'done': done,
        'rir': rir,
        'rpe': rpe,
        'phase': phase,
        'warmup': warmup,
        'type': type,
        'drops': drops?.map((DropEntry d) => d.toJson()).toList(),
        'clusters': clusters?.map((ClusterEntry c) => c.toJson()).toList(),
        'sides': sides?.toJson(),
      });

  @override
  List<Object?> get props =>
      <Object?>[w, r, done, rir, rpe, phase, warmup, type, drops, clusters, sides, extra];
}
