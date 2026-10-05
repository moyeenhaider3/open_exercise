// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/reminder_js.dart';
import 'package:open_exercise/core/js/modules/superset_flow_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> phase5Dispatch(JsEngineService engine) {
  final SupersetFlowJs supersetFlow = engine.supersetFlow;
  final ReminderJs reminder = engine.reminder;

  return <String, ParityCall>{
    'supersetFlow.restAfterSet': (List<Object?> args) {
      final Map<String, Object?> opts = jsonMapArg(args, 0);
      final bool unitDone = opts['unitDone'] == true;
      final bool lastUnit = opts['lastUnit'] == true;
      return toPlainJson(
        supersetFlow.restAfterSet(unitDone: unitDone, lastUnit: lastUnit),
      );
    },
    'supersetFlow.restOnRecheck': (List<Object?> args) {
      final Map<String, Object?> opts = jsonMapArg(args, 0);
      final bool timerRunning = opts['timerRunning'] == true;
      final bool unitDone = opts['unitDone'] == true;
      final bool lastUnit = opts['lastUnit'] == true;
      return toPlainJson(
        supersetFlow.restOnRecheck(
          timerRunning: timerRunning,
          unitDone: unitDone,
          lastUnit: lastUnit,
        ),
      );
    },
    'supersetFlow.restSecFor': (List<Object?> args) {
      final List<Object?> rawEntries = jsonListArg(args, 0);
      final List<WorkoutEntry> entries = rawEntries
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) =>
              WorkoutEntry.fromJson(Map<String, Object?>.from(m)))
          .toList();
      final List<Object?> rawUnit = jsonListArg(args, 1);
      final List<int> unit = rawUnit.map((Object? e) => (e as num).toInt()).toList();
      final num defaultRestSec = argAt(args, 2) as num? ?? 0;
      return toPlainJson(
        supersetFlow.restSecFor(entries, unit, defaultRestSec),
      );
    },
    'supersetFlow.warmupRestSecFor': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final int setIdx = (argAt(args, 1) as num).toInt();
      final int workRestSec = (argAt(args, 2) as num).toInt();
      return toPlainJson(
        supersetFlow.warmupRestSecFor(entry, setIdx, workRestSec),
      );
    },
    'reminder.reminderDays': (List<Object?> args) {
      final GymState state = GymState.fromJson(jsonMapArg(args, 0));
      final int nowMs = (argAt(args, 1) as num).toInt();
      return toPlainJson(reminder.reminderDays(state, nowMs));
    },
    'reminder.buildReminderNotifications': (List<Object?> args) {
      final GymState state = GymState.fromJson(jsonMapArg(args, 0));
      final int nowMs = (argAt(args, 1) as num).toInt();
      return toPlainJson(reminder.buildReminderNotifications(state, nowMs));
    },
  };
}

