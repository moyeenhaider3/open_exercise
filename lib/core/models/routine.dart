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
  static const Set<String> knownKeys = _known;

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

  /// Returns a copy with the given fields replaced. Uses the same sentinel pattern as
  /// [Workout.copyWith]: explicit null clears the field and writes `key: null` into [extra],
  /// while non-null removes stale demoted keys.
  RoutineExercise copyWith({
    Object? id = _unset,
    Object? sets = _unset,
    Object? reps = _unset,
    Object? weight = _unset,
    Object? note = _unset,
    Object? sg = _unset,
    Map<String, Object?>? extra,
  }) {
    final Map<String, Object?> nextExtra = <String, Object?>{...(extra ?? this.extra)};
    T? pick<T>(Object? value, T? current, String key) {
      if (identical(value, _unset)) return current;
      if (value == null) {
        nextExtra[key] = null;
        return null;
      }
      nextExtra.remove(key);
      return value as T;
    }

    return RoutineExercise(
      id: pick<String>(id, this.id, 'id'),
      sets: pick<num>(sets, this.sets, 'sets'),
      reps: pick<num>(reps, this.reps, 'reps'),
      weight: pick<num>(weight, this.weight, 'weight'),
      note: pick<String>(note, this.note, 'note'),
      sg: pick<String>(sg, this.sg, 'sg'),
      extra: Map<String, Object?>.unmodifiable(nextExtra),
    );
  }

  static const Object _unset = Object();

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
  static const Set<String> knownKeys = _known;

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

  /// Returns a copy with the given fields replaced. Uses the same sentinel pattern as
  /// [Workout.copyWith]: explicit null clears the field and writes `key: null` into [extra],
  /// while non-null removes stale demoted keys.
  Routine copyWith({
    Object? id = _unset,
    Object? name = _unset,
    Object? emoji = _unset,
    Object? ex = _unset,
    Map<String, Object?>? extra,
  }) {
    final Map<String, Object?> nextExtra = <String, Object?>{...(extra ?? this.extra)};
    T? pick<T>(Object? value, T? current, String key) {
      if (identical(value, _unset)) return current;
      if (value == null) {
        nextExtra[key] = null;
        return null;
      }
      nextExtra.remove(key);
      return value as T;
    }

    return Routine(
      id: pick<String>(id, this.id, 'id'),
      name: pick<String>(name, this.name, 'name'),
      emoji: pick<String>(emoji, this.emoji, 'emoji'),
      ex: pick<List<RoutineExercise>>(ex, this.ex, 'ex'),
      extra: Map<String, Object?>.unmodifiable(nextExtra),
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => <Object?>[id, name, emoji, ex, extra];
}
