// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/workout_model_js.dart';
import 'package:open_exercise/core/models/set_entry.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> workoutModelDispatch(JsEngineService engine) {
  final WorkoutModelJs wm = engine.workoutModel;

  return <String, ParityCall>{
    'workoutModel.phaseForSet': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final String? fallback = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(wm.phaseForSet(set, fallback: fallback));
    },
    'workoutModel.isWarmupRow': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.isWarmupRow(set));
    },
    'workoutModel.setType': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.setType(set));
    },
    'workoutModel.isDropSet': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.isDropSet(set));
    },
    'workoutModel.isRestPauseSet': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.isRestPauseSet(set));
    },
    'workoutModel.dropsOf': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.dropsOf(set));
    },
    'workoutModel.clustersOf': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.clustersOf(set));
    },
    'workoutModel.extraVolumeOf': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.extraVolumeOf(set));
    },
    'workoutModel.addDrop': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final DropEntry drop = DropEntry.fromJson(jsonMapArg(args, 1));
      return toPlainJson(wm.addDrop(set, drop));
    },
    'workoutModel.addCluster': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final ClusterEntry cluster = ClusterEntry.fromJson(jsonMapArg(args, 1));
      return toPlainJson(wm.addCluster(set, cluster));
    },
    'workoutModel.removeDropAt': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      return toPlainJson(wm.removeDropAt(set, i));
    },
    'workoutModel.removeClusterAt': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      return toPlainJson(wm.removeClusterAt(set, i));
    },
    'workoutModel.setDropAt': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      final Map<String, Object?> patch = jsonMapArg(args, 2);
      return toPlainJson(wm.setDropAt(set, i, patch));
    },
    'workoutModel.setClusterAt': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      final Map<String, Object?> patch = jsonMapArg(args, 2);
      return toPlainJson(wm.setClusterAt(set, i, patch));
    },
    'workoutModel.nextDropWeight': (List<Object?> args) {
      final num prevWeight = argAt(args, 0) as num;
      final num? pct = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      return toPlainJson(wm.nextDropWeight(prevWeight, pct: pct));
    },
    'workoutModel.nextBurstReps': (List<Object?> args) {
      final num? prevReps = argAt(args, 0) as num?;
      return toPlainJson(wm.nextBurstReps(prevReps));
    },
    'workoutModel.splitBurstReps': (List<Object?> args) {
      final num? total = argAt(args, 0) as num?;
      return toPlainJson(wm.splitBurstReps(total));
    },
    'workoutModel.isSideSet': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.isSideSet(set));
    },
    'workoutModel.hasCompletedWork': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.hasCompletedWork(set));
    },
    'workoutModel.completedVolumeOf': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.completedVolumeOf(set));
    },
    'workoutModel.makeSideSet': (List<Object?> args) {
      final SetEntry? row = hasArg(args, 0) && argAt(args, 0) != null
          ? SetEntry.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(wm.makeSideSet(row));
    },
    'workoutModel.syncSideAggregate': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      return toPlainJson(wm.syncSideAggregate(row));
    },
    'workoutModel.setSideField': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final String side = argAt(args, 1) as String;
      final String field = argAt(args, 2) as String;
      final Object? value = argAt(args, 3);
      return toPlainJson(wm.setSideField(row, side, field, value));
    },
    'workoutModel.toggleSide': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final String side = argAt(args, 1) as String;
      return toPlainJson(wm.toggleSide(row, side));
    },
    'workoutModel.addSideDrop': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final num? pct = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      return toPlainJson(wm.addSideDrop(row, pct: pct));
    },
    'workoutModel.removeSideDropAt': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      return toPlainJson(wm.removeSideDropAt(row, i));
    },
    'workoutModel.setSideDropAt': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final String side = argAt(args, 1) as String;
      final int i = (argAt(args, 2) as num).round();
      final Map<String, Object?> patch = jsonMapArg(args, 3);
      return toPlainJson(wm.setSideDropAt(row, side, i, patch));
    },
    'workoutModel.addSideCluster': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final num? restSec = hasArg(args, 1) ? argAt(args, 1) as num? : null;
      return toPlainJson(wm.addSideCluster(row, restSec: restSec));
    },
    'workoutModel.removeSideClusterAt': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final int i = (argAt(args, 1) as num).round();
      return toPlainJson(wm.removeSideClusterAt(row, i));
    },
    'workoutModel.setSideClusterAt': (List<Object?> args) {
      final SetEntry row = SetEntry.fromJson(jsonMapArg(args, 0));
      final String side = argAt(args, 1) as String;
      final int i = (argAt(args, 2) as num).round();
      final num? r = argAt(args, 3) as num?;
      return toPlainJson(wm.setSideClusterAt(row, side, i, r));
    },
    'workoutModel.normalizeMode': (List<Object?> args) {
      final Object? value = argAt(args, 0);
      final String? fallback = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(wm.normalizeMode(value, fallback: fallback));
    },
    'workoutModel.modeForSet': (List<Object?> args) {
      final SetEntry set = SetEntry.fromJson(jsonMapArg(args, 0));
      final Map<String, Object?>? target = hasArg(args, 1) && argAt(args, 1) != null
          ? jsonMapArg(args, 1)
          : null;
      return toPlainJson(wm.modeForSet(set, target: target));
    },
    'workoutModel.modeForEntry': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final String? fallback = hasArg(args, 1) ? argAt(args, 1) as String? : null;
      return toPlainJson(wm.modeForEntry(entry, fallback: fallback));
    },
  };
}
