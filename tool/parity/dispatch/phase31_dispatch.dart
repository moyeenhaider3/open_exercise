// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/backfill_js.dart';
import 'package:open_exercise/core/js/modules/units_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> phase31Dispatch(JsEngineService engine) {
  final BackfillJs backfill = engine.backfill;
  final UnitsJs units = engine.units;

  return <String, ParityCall>{
    // Backfill
    'backfill.workoutsOn': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(backfill.workoutsOn(s, iso));
    },
    'backfill.backfillStart': (List<Object?> args) {
      final String iso = argAt(args, 0) as String;
      final String? time = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(backfill.backfillStart(iso, time));
    },
    'backfill.backfillEnd': (List<Object?> args) {
      final Workout active = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(backfill.backfillEnd(active));
    },
    'backfill.insertChronological': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<Workout> workouts = rawList
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => Workout.fromJson(Map<String, Object?>.from(m)))
          .toList();
      final Workout w = Workout.fromJson(jsonMapArg(args, 1));
      return toPlainJson(backfill.insertChronological(workouts, w));
    },
    'backfill.completeBackfill': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<Workout> workouts = rawList
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => Workout.fromJson(Map<String, Object?>.from(m)))
          .toList();
      final Workout active = Workout.fromJson(jsonMapArg(args, 1));
      final Workout w = Workout.fromJson(jsonMapArg(args, 2));
      return toPlainJson(backfill.completeBackfill(workouts, active, w));
    },

    // Units
    'units.convertWeight': (List<Object?> args) {
      final Object? value = argAt(args, 0);
      final String from = argAt(args, 1) as String;
      final String to = argAt(args, 2) as String;
      if (value is num?) {
        return toPlainJson(units.convertWeight(value, from, to));
      }
      return toPlainJson(value);
    },
    'units.convertBodyWeight': (List<Object?> args) {
      final Object? value = argAt(args, 0);
      final String from = argAt(args, 1) as String;
      final String to = argAt(args, 2) as String;
      if (value is num?) {
        return toPlainJson(units.convertBodyWeight(value, from, to));
      }
      return toPlainJson(value);
    },
    'units.convertStateUnit': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String to = argAt(args, 1) as String;
      return toPlainJson(units.convertStateUnit(s, to));
    },
  };
}
