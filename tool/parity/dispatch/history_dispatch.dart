// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/models/history_models.dart';
import 'package:open_exercise/core/js/modules/history_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/routine.dart';
import 'package:open_exercise/core/models/set_entry.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> historyDispatch(JsEngineService engine) {
  final HistoryJs hist = engine.history;

  return <String, ParityCall>{
    'history.modeOf': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.modeOf(cfg));
    },
    'history.isTimed': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.isTimed(cfg));
    },
    'history.isBw': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.isBw(cfg));
    },
    'history.isPerSide': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.isPerSide(cfg));
    },
    'history.sideReps': (List<Object?> args) {
      final num? reps = argAt(args, 0) as num?;
      return toPlainJson(hist.sideReps(reps));
    },
    'history.repStep': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.repStep(cfg));
    },
    'history.stepEffort': (List<Object?> args) {
      final String kind = argAt(args, 0) as String;
      final num? cur = argAt(args, 1) as num?;
      final num dir = argAt(args, 2) as num;
      return toPlainJson(hist.stepEffort(kind, cur, dir));
    },
    'history.capEffort': (List<Object?> args) {
      final String kind = argAt(args, 0) as String;
      final num? v = argAt(args, 1) as num?;
      return toPlainJson(hist.capEffort(kind, v));
    },
    'history.effortOf': (List<Object?> args) {
      final GymState? s = hasArg(args, 0) && argAt(args, 0) != null
          ? GymState.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.effortOf(s));
    },
    'history.defaultConfig': (List<Object?> args) {
      final String id = argAt(args, 0) as String;
      final String? mode = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(hist.defaultConfig(id, mode));
    },
    'history.cleanupSg': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<RoutineExercise> ex = rawList
          .map((Object? item) => RoutineExercise.fromJson(item as Map<String, Object?>))
          .toList();
      return toPlainJson(hist.cleanupSg(ex));
    },
    'history.pairAdjacent': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<RoutineExercise> items = rawList
          .map((Object? item) => RoutineExercise.fromJson(item as Map<String, Object?>))
          .toList();
      final int first = (argAt(args, 1) as num).toInt();
      final int second = (argAt(args, 2) as num).toInt();
      final String? groupId = hasArg(args, 3) ? argAt(args, 3) as String? : null;
      return toPlainJson(hist.pairAdjacent(items, first, second, groupId));
    },
    'history.unpairSuperset': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<RoutineExercise> items = rawList
          .map((Object? item) => RoutineExercise.fromJson(item as Map<String, Object?>))
          .toList();
      final int idx = (argAt(args, 1) as num).toInt();
      return toPlainJson(hist.unpairSuperset(items, idx));
    },
    'history.entryExcluded': (List<Object?> args) {
      final Workout? w = hasArg(args, 0) && argAt(args, 0) != null
          ? Workout.fromJson(jsonMapArg(args, 0))
          : null;
      final WorkoutEntry? entry = hasArg(args, 1) && argAt(args, 1) != null
          ? WorkoutEntry.fromJson(jsonMapArg(args, 1))
          : null;
      return toPlainJson(hist.entryExcluded(w, entry));
    },
    'history.lastEntryFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(hist.lastEntryFor(s, exId));
    },
    'history.pinnedNoteFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(hist.pinnedNoteFor(s, exId));
    },
    'history.exNoteFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(hist.exNoteFor(s, exId));
    },
    'history.freestyleConfig': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final RoutineExercise cfg = RoutineExercise.fromJson(jsonMapArg(args, 1));
      return toPlainJson(hist.freestyleConfig(s, cfg));
    },
    'history.bestWeightFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(hist.bestWeightFor(s, exId));
    },
    'history.effectiveRoutineIds': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(hist.effectiveRoutineIds(s, iso));
    },
    'history.effectiveRoutines': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(hist.effectiveRoutines(s, iso));
    },
    'history.effectiveRoutineId': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(hist.effectiveRoutineId(s, iso));
    },
    'history.effectiveRoutine': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(hist.effectiveRoutine(s, iso));
    },
    'history.nextTrainingDay': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String iso = argAt(args, 1) as String;
      return toPlainJson(hist.nextTrainingDay(s, iso));
    },
    'history.buildSets': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final RoutineExercise cfg = RoutineExercise.fromJson(jsonMapArg(args, 1));
      final BuildSetsOptions? options = hasArg(args, 2) && argAt(args, 2) != null
          ? BuildSetsOptions.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(hist.buildSets(s, cfg, options: options));
    },
    'history.applyIntensifierPlan': (List<Object?> args) {
      final List<Object?> rawSets = jsonListArg(args, 0);
      final List<SetEntry> sets = rawSets
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final RoutineExercise cfg = RoutineExercise.fromJson(jsonMapArg(args, 1));
      return toPlainJson(hist.applyIntensifierPlan(sets, cfg));
    },
    'history.workoutVolume': (List<Object?> args) {
      final Workout w = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.workoutVolume(w));
    },
    'history.setUnits': (List<Object?> args) {
      final SetEntry s = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.setUnits(s));
    },
    'history.doneUnits': (List<Object?> args) {
      final SetEntry s = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.doneUnits(s));
    },
    'history.setUnitsTotal': (List<Object?> args) {
      final List<Object?> rawEntries = jsonListArg(args, 0);
      final List<WorkoutEntry> entries = rawEntries
          .map((Object? item) => WorkoutEntry.fromJson(item as Map<String, Object?>))
          .toList();
      return toPlainJson(hist.setUnitsTotal(entries));
    },
    'history.setsDone': (List<Object?> args) {
      final Workout w = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.setsDone(w));
    },
    'history.setsDoneActive': (List<Object?> args) {
      final Workout a = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.setsDoneActive(a));
    },
    'history.lastBW': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.lastBW(s));
    },
    'history.supersetUnits': (List<Object?> args) {
      final List<Object?> items = jsonListArg(args, 0);
      return toPlainJson(hist.supersetUnits(items));
    },
    'history.moveSupersetUnit': (List<Object?> args) {
      final List<Object?> rawItems = jsonListArg(args, 0);
      final List<RoutineExercise> items = rawItems
          .map((Object? item) => RoutineExercise.fromJson(item as Map<String, Object?>))
          .toList();
      final int index = (argAt(args, 1) as num).toInt();
      final int direction = (argAt(args, 2) as num).toInt();
      return toPlainJson(hist.moveSupersetUnit(items, index, direction));
    },
    'history.unitOf': (List<Object?> args) {
      final List<Object?> rawUnits = jsonListArg(args, 0);
      final List<List<int>> units = rawUnits
          .map((Object? group) => (group as List).map((Object? item) => (item as num).toInt()).toList())
          .toList();
      final int idx = (argAt(args, 1) as num).toInt();
      return toPlainJson(hist.unitOf(units, idx));
    },
    'history.streakWeeks': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.streakWeeks(s));
    },
    'history.cascadeWeight': (List<Object?> args) {
      final List<Object?> rawRows = jsonListArg(args, 0);
      final List<SetEntry> rows = rawRows
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final int from = (argAt(args, 1) as num).toInt();
      final num? value = argAt(args, 2) as num?;
      return toPlainJson(hist.cascadeWeight(rows, from, value));
    },
    'history.rerampWarmups': (List<Object?> args) {
      final List<Object?> rawRows = jsonListArg(args, 0);
      final List<SetEntry> rows = rawRows
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final num? step = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      return toPlainJson(hist.rerampWarmups(rows, step: step));
    },
    'history.insertWarmupRow': (List<Object?> args) {
      final List<Object?> rawRows = jsonListArg(args, 0);
      final List<SetEntry> rows = rawRows
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final String mode = argAt(args, 1) as String;
      final RoutineExercise target = RoutineExercise.fromJson(jsonMapArg(args, 2));
      final num? step = hasArg(args, 3) ? argAt(args, 3) as num? : null;
      return toPlainJson(hist.insertWarmupRow(rows, mode, target, step: step));
    },
    'history.removeRowAt': (List<Object?> args) {
      final List<Object?> rawRows = jsonListArg(args, 0);
      final List<SetEntry> rows = rawRows
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final int i = (argAt(args, 1) as num).toInt();
      return toPlainJson(hist.removeRowAt(rows, i));
    },
    'history.workSetsDone': (List<Object?> args) {
      final Workout w = Workout.fromJson(jsonMapArg(args, 0));
      return toPlainJson(hist.workSetsDone(w));
    },
    'history.metricRowsForEntry': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final String? mode = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(hist.metricRowsForEntry(entry, mode));
    },
    'history.metricModeForEntry': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final String? fallback = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(hist.metricModeForEntry(entry, fallback: fallback));
    },
    'history.bestWeightForEntry': (List<Object?> args) {
      final WorkoutEntry? entry = hasArg(args, 0) && argAt(args, 0) != null
          ? WorkoutEntry.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(hist.bestWeightForEntry(entry));
    },
  };
}
