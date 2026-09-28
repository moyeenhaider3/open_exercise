// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/onerm_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> onermDispatch(JsEngineService engine) {
  final OnermJs onerm = engine.onerm;

  return <String, ParityCall>{
    'onerm.estimate1RM': (List<Object?> args) {
      final num w = argAt(args, 0) as num;
      final num r = argAt(args, 1) as num;
      final String? formula = hasArg(args, 2) ? argAt(args, 2) as String? : null;
      return toPlainJson(onerm.estimate1RM(w, r, formula: formula));
    },
    'onerm.bestSetOf': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final String? formula = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(onerm.bestSetOf(entry, formula: formula));
    },
    'onerm.e1rmSeries': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      final String? formula = hasArg(args, 2) ? argAt(args, 2) as String? : null;
      return toPlainJson(onerm.e1rmSeries(s, exId, formula: formula));
    },
    'onerm.best1RM': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      final String? formula = hasArg(args, 2) ? argAt(args, 2) as String? : null;
      return toPlainJson(onerm.best1RM(s, exId, formula: formula));
    },
    'onerm.is1RMRecord': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 2));
      final String? formula = hasArg(args, 3) ? argAt(args, 3) as String? : null;
      return toPlainJson(onerm.is1RMRecord(s, exId, entry, formula: formula));
    },
  };
}
