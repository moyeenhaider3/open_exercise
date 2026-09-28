// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/json_passthrough.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../js_codec.dart';

/// Specification of an effort rating scale (RIR or RPE).
class EffortScale extends Equatable implements JsonEncodable {
  const EffortScale({
    this.f,
    this.hd,
    this.step,
    this.min,
    this.max,
    this.extra = const <String, Object?>{},
  });

  final String? f;
  final String? hd;
  final double? step;
  final double? min;
  final double? max;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'f', 'hd', 'step', 'min', 'max'};

  factory EffortScale.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return EffortScale(
      f: reader.string('f'),
      hd: reader.string('hd'),
      step: reader.number('step')?.toDouble(),
      min: reader.number('min')?.toDouble(),
      max: reader.number('max')?.toDouble(),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'f': f,
        'hd': hd,
        'step': step,
        'min': min,
        'max': max,
      });

  @override
  List<Object?> get props => <Object?>[f, hd, step, min, max, extra];
}

/// Options passed into `buildSets` and `buildWorkSets`.
class BuildSetsOptions extends Equatable implements JsonEncodable {
  const BuildSetsOptions({
    this.step,
    this.preferLast,
    this.useTarget,
    this.extra = const <String, Object?>{},
  });

  final num? step;
  final bool? preferLast;
  final bool? useTarget;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'step', 'preferLast', 'useTarget'};

  factory BuildSetsOptions.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return BuildSetsOptions(
      step: reader.number('step'),
      preferLast: reader.boolean('preferLast'),
      useTarget: reader.boolean('useTarget'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'step': step,
        'preferLast': preferLast,
        'useTarget': useTarget,
      });

  @override
  List<Object?> get props => <Object?>[step, preferLast, useTarget, extra];
}

/// Pinned session note for an exercise.
class PinnedNote extends Equatable implements JsonEncodable {
  const PinnedNote({
    this.note,
    this.d,
    this.extra = const <String, Object?>{},
  });

  final String? note;
  final String? d;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'note', 'd'};

  factory PinnedNote.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return PinnedNote(
      note: reader.string('note'),
      d: reader.string('d'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'note': note,
        'd': d,
      });

  @override
  List<Object?> get props => <Object?>[note, d, extra];
}

/// Result of querying the next trainable day in a plan.
class TrainingDay extends Equatable implements JsonEncodable {
  const TrainingDay({
    this.iso,
    this.weekday,
    this.routines,
    this.routine,
    this.extra = const <String, Object?>{},
  });

  final String? iso;
  final int? weekday;
  final List<Routine>? routines;
  final Routine? routine;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'iso', 'weekday', 'routines', 'routine'};

  factory TrainingDay.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    final Map<String, Object?>? routineMap = reader.map('routine');

    return TrainingDay(
      iso: reader.string('iso'),
      weekday: reader.integer('weekday'),
      routines: reader.objectList<Routine>('routines', Routine.fromJson),
      routine: routineMap != null ? Routine.fromJson(routineMap) : null,
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'iso': iso,
        'weekday': weekday,
        'routines': routines?.map((Routine r) => r.toJson()).toList(),
        'routine': routine?.toJson(),
      });

  @override
  List<Object?> get props => <Object?>[iso, weekday, routines, routine, extra];
}

/// Combined session entries and routines produced by `sessionMerge.buildCombinedEntries`.
class CombinedSession extends Equatable implements JsonEncodable {
  const CombinedSession({
    this.entries,
    this.routineIds,
    this.routines,
    this.extra = const <String, Object?>{},
  });

  final List<WorkoutEntry>? entries;
  final List<String>? routineIds;
  final List<Routine>? routines;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'entries', 'routineIds', 'routines'};

  factory CombinedSession.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return CombinedSession(
      entries: reader.objectList<WorkoutEntry>('entries', WorkoutEntry.fromJson),
      routineIds: reader.stringList('routineIds'),
      routines: reader.objectList<Routine>('routines', Routine.fromJson),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'entries': entries?.map((WorkoutEntry e) => e.toJson()).toList(),
        'routineIds': routineIds,
        'routines': routines?.map((Routine r) => r.toJson()).toList(),
      });

  @override
  List<Object?> get props => <Object?>[entries, routineIds, routines, extra];
}
