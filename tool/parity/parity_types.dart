// SPDX-License-Identifier: AGPL-3.0-or-later

/// Shared types and serialization helpers for the JS parity bridge and test fixtures.
///
/// This file is tool-only, is never imported from lib/, and is not a test.
library;

import 'package:open_exercise/core/js/js_codec.dart';
import 'package:open_exercise/core/models/bodyweight_entry.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/routine.dart';
import 'package:open_exercise/core/models/set_entry.dart';
import 'package:open_exercise/core/models/workout.dart';

typedef ParityCall = Object? Function(List<Object?> args);

/// Returns true if [v] is an undefined marker map `{"$undefined": true}`.
bool isUndefinedMarker(Object? v) {
  if (v is Map) {
    return v.length == 1 && v['\$undefined'] == true;
  }
  return false;
}

/// Returns the argument at index [i], or [jsUndefined] if omitted or marked undefined.
Object? argAt(List<Object?> args, int i) {
  if (i >= args.length) {
    return jsUndefined;
  }
  final Object? v = args[i];
  if (isUndefinedMarker(v)) {
    return jsUndefined;
  }
  return v;
}

/// Returns true if an argument at index [i] was provided and not marked undefined.
bool hasArg(List<Object?> args, int i) {
  return !identical(argAt(args, i), jsUndefined);
}

/// Strictly extracts a JSON map argument at index [i].
Map<String, Object?> jsonMapArg(List<Object?> args, int i) {
  final Object? v = argAt(args, i);
  if (v is Map) {
    return Map<String, Object?>.from(v);
  }
  throw ArgumentError.value(v, 'args[$i]', 'Expected Map<String, Object?>');
}

/// Strictly extracts a JSON list argument at index [i].
List<Object?> jsonListArg(List<Object?> args, int i) {
  final Object? v = argAt(args, i);
  if (v is List) {
    return List<Object?>.from(v);
  }
  throw ArgumentError.value(v, 'args[$i]', 'Expected List<Object?>');
}

/// Recursively converts model instances and structures into plain JSON.
Object? toPlainJson(Object? v) {
  if (v == null) {
    return null;
  }
  if (v is num || v is String || v is bool) {
    return v;
  }
  if (v is JsonEncodable) {
    return toPlainJson(v.toJson());
  }
  if (v is SetEntry) {
    return toPlainJson(v.toJson());
  }
  if (v is DropEntry) {
    return toPlainJson(v.toJson());
  }
  if (v is ClusterEntry) {
    return toPlainJson(v.toJson());
  }
  if (v is SideSets) {
    return toPlainJson(v.toJson());
  }
  if (v is WorkoutEntry) {
    return toPlainJson(v.toJson());
  }
  if (v is Workout) {
    return toPlainJson(v.toJson());
  }
  if (v is Routine) {
    return toPlainJson(v.toJson());
  }
  if (v is RoutineExercise) {
    return toPlainJson(v.toJson());
  }
  if (v is GymState) {
    return toPlainJson(v.toJson());
  }
  if (v is BodyweightEntry) {
    return toPlainJson(v.toJson());
  }
  if (v is List) {
    return v.map(toPlainJson).toList();
  }
  if (v is Map) {
    final Map<String, Object?> map = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in v.entries) {
      map[entry.key.toString()] = toPlainJson(entry.value);
    }
    return map;
  }
  throw ArgumentError('Unsupported type in toPlainJson: ${v.runtimeType}: $v');
}
