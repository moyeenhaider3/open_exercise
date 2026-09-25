// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'json_passthrough.dart';

/// One exercise line inside a [Routine] (`../openGym/frontend/src/lib/starter.js` line 45:
/// `{ id, sets, reps, weight: 0 }`; `note` and `sg` -- the superset group id, shared by
/// consecutive entries, `../openGym/frontend/src/lib/history.js` lines 163-185 -- come from the
/// same routine-exercise shape used by the coach bundle tests). Unmodelled keys (`mode`,
/// `targets`, `noProg`, etc. -- coach/target metadata, not yet ported) stay in [extra].
class RoutineExercise extends Equatable {
  const RoutineExercise({
    this.id,
    this.sets,
    this.reps,
    this.weight,
    this.note,
    this.sg,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final num? sets;
  final num? reps;
  final num? weight;
  final String? note;
  final String? sg;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'sets', 'reps', 'weight', 'note', 'sg'};

  factory RoutineExercise.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return RoutineExercise(
      id: reader.string('id'),
      sets: reader.number('sets'),
      reps: reader.number('reps'),
      weight: reader.number('weight'),
      note: reader.string('note'),
      sg: reader.string('sg'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'note': note,
        'sg': sg,
      });

  @override
  List<Object?> get props => <Object?>[id, sets, reps, weight, note, sg, extra];
}

/// A saved training plan (`../openGym/frontend/src/lib/starter.js` `build`;
/// `../openGym/api/openapi.yaml` Routine schema). `__futureRoutineKey` and any other unknown
/// top-level key survive unchanged via [extra].
class Routine extends Equatable {
  const Routine({
    this.id,
    this.name,
    this.emoji,
    this.ex,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final String? name;
  final String? emoji;
  final List<RoutineExercise>? ex;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'name', 'emoji', 'ex'};

  factory Routine.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return Routine(
      id: reader.string('id'),
      name: reader.string('name'),
      emoji: reader.string('emoji'),
      ex: reader.objectList<RoutineExercise>('ex', RoutineExercise.fromJson),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'name': name,
        'emoji': emoji,
        'ex': ex?.map((RoutineExercise e) => e.toJson()).toList(),
      });

  @override
  List<Object?> get props => <Object?>[id, name, emoji, ex, extra];
}
