// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/exercises_js.dart';
import 'package:open_exercise/core/models/state_parts.dart';

import '../parity_types.dart';

Map<String, ParityCall> exercisesDispatch(JsEngineService engine) {
  final ExercisesJs exercises = engine.exercises;

  return <String, ParityCall>{
    'exercises.registerCustom': (List<Object?> args) {
      final List<Object?>? rawList = argAt(args, 0) as List<Object?>?;
      final List<CustomExercise>? list = rawList
          ?.whereType<Map<String, Object?>>()
          .map(CustomExercise.fromJson)
          .toList();
      exercises.registerCustom(list);
      return null;
    },
    'exercises.isAssisted': (List<Object?> args) {
      final Object? idOrEx = argAt(args, 0);
      return toPlainJson(exercises.isAssisted(idOrEx));
    },
    'exercises.betterWeight': (List<Object?> args) {
      final Object? idOrEx = argAt(args, 0);
      final num a = argAt(args, 1) as num;
      final num b = argAt(args, 2) as num;
      return toPlainJson(exercises.betterWeight(idOrEx, a, b));
    },
    'exercises.beatsWeight': (List<Object?> args) {
      final Object? idOrEx = argAt(args, 0);
      final num w = argAt(args, 1) as num;
      final num prev = argAt(args, 2) as num;
      return toPlainJson(exercises.beatsWeight(idOrEx, w, prev));
    },
    'exercises.isCardio': (List<Object?> args) {
      final Object? idOrEx = argAt(args, 0);
      return toPlainJson(exercises.isCardio(idOrEx));
    },
    'exercises.isBodyweightEq': (List<Object?> args) {
      final Object? idOrEx = argAt(args, 0);
      return toPlainJson(exercises.isBodyweightEq(idOrEx));
    },
  };
}
