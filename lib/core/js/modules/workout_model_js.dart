// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `workout-model.js` module.
///
/// Phase resolution, set types, drops, clusters, unilateral side sets, and
/// volume aggregations delegate directly to openGym's JavaScript library (JS-04).
library;

import '../../models/set_entry.dart';
import '../../models/workout.dart';
import '../js_bridge_exception.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

final class WorkoutModelJs {
  const WorkoutModelJs(this._engine);

  final JsEngineService _engine;

  /// Resolves the phase of a set row ('work' or 'warmup').
  String phaseForSet(SetEntry set, {String? fallback}) {
    final Object? result = _engine.call(
      'workoutModel.phaseForSet',
      <Object?>[set.toJson(), fallback ?? jsUndefined],
    );
    return jsString(result, 'workoutModel.phaseForSet');
  }

  /// True if the set resolves to a warmup phase.
  bool isWarmupRow(SetEntry set) {
    final Object? result = _engine.call('workoutModel.isWarmupRow', <Object?>[set.toJson()]);
    return jsBool(result, 'workoutModel.isWarmupRow');
  }

  /// Resolves set type ('straight', 'dropset', or 'restpause').
  String setType(SetEntry set) {
    final Object? result = _engine.call('workoutModel.setType', <Object?>[set.toJson()]);
    return jsString(result, 'workoutModel.setType');
  }

  /// True if the set is a dropset.
  bool isDropSet(SetEntry set) {
    final Object? result = _engine.call('workoutModel.isDropSet', <Object?>[set.toJson()]);
    return jsBool(result, 'workoutModel.isDropSet');
  }

  /// True if the set is a rest-pause set.
  bool isRestPauseSet(SetEntry set) {
    final Object? result = _engine.call('workoutModel.isRestPauseSet', <Object?>[set.toJson()]);
    return jsBool(result, 'workoutModel.isRestPauseSet');
  }

  /// Weight drops of a dropset, oldest first; empty for other set types.
  List<DropEntry> dropsOf(SetEntry? set) {
    final Object? result = _engine.call(
      'workoutModel.dropsOf',
      <Object?>[set != null ? set.toJson() : jsUndefined],
    );
    return jsListOf<DropEntry>(result, 'workoutModel.dropsOf', DropEntry.fromJson);
  }

  /// Short-rest bursts of a rest-pause set; empty for other set types.
  List<ClusterEntry> clustersOf(SetEntry? set) {
    final Object? result = _engine.call(
      'workoutModel.clustersOf',
      <Object?>[set != null ? set.toJson() : jsUndefined],
    );
    return jsListOf<ClusterEntry>(result, 'workoutModel.clustersOf', ClusterEntry.fromJson);
  }

  /// Weight x reps volume from drops on top of the main set.
  double extraVolumeOf(SetEntry? set) {
    final Object? result = _engine.call(
      'workoutModel.extraVolumeOf',
      <Object?>[set != null ? set.toJson() : jsUndefined],
    );
    return jsDouble(result, 'workoutModel.extraVolumeOf');
  }

  /// Appends a weight drop to a set, marking it a dropset.
  SetEntry addDrop(SetEntry set, DropEntry drop) {
    final Object? result = _engine.call(
      'workoutModel.addDrop',
      <Object?>[set.toJson(), drop.toJson()],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.addDrop'));
  }

  /// Appends a short-rest burst to a set, marking it a rest-pause set.
  SetEntry addCluster(SetEntry set, ClusterEntry cluster) {
    final Object? result = _engine.call(
      'workoutModel.addCluster',
      <Object?>[set.toJson(), cluster.toJson()],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.addCluster'));
  }

  /// Removes one drop by index. Reverts to straight set if drops become empty.
  SetEntry removeDropAt(SetEntry set, int i) {
    final Object? result = _engine.call(
      'workoutModel.removeDropAt',
      <Object?>[set.toJson(), i],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.removeDropAt'));
  }

  /// Removes one burst by index. Reverts to straight set if clusters become empty.
  SetEntry removeClusterAt(SetEntry set, int i) {
    final Object? result = _engine.call(
      'workoutModel.removeClusterAt',
      <Object?>[set.toJson(), i],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.removeClusterAt'));
  }

  /// Patches one drop's fields in place.
  SetEntry setDropAt(SetEntry set, int i, Map<String, Object?> patch) {
    final Object? result = _engine.call(
      'workoutModel.setDropAt',
      <Object?>[set.toJson(), i, patch],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.setDropAt'));
  }

  /// Patches one cluster's fields in place.
  SetEntry setClusterAt(SetEntry set, int i, Map<String, Object?> patch) {
    final Object? result = _engine.call(
      'workoutModel.setClusterAt',
      <Object?>[set.toJson(), i, patch],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.setClusterAt'));
  }

  /// Suggested weight for the next drop (pct% lighter, rounded to .5).
  double nextDropWeight(num prevWeight, {num? pct}) {
    final Object? result = _engine.call(
      'workoutModel.nextDropWeight',
      <Object?>[prevWeight, pct ?? jsUndefined],
    );
    return jsDouble(result, 'workoutModel.nextDropWeight');
  }

  /// Suggested reps for the next rest-pause burst.
  int nextBurstReps(num? prevReps) {
    final Object? result = _engine.call(
      'workoutModel.nextBurstReps',
      <Object?>[prevReps],
    );
    return jsInt(result, 'workoutModel.nextBurstReps');
  }

  /// Splits a rest-pause total rep count into descending bursts.
  List<int> splitBurstReps(num? total) {
    final Object? result = _engine.call(
      'workoutModel.splitBurstReps',
      <Object?>[total],
    );
    final List<Object?> raw = jsList(result, 'workoutModel.splitBurstReps');
    final List<int> bursts = <int>[];
    for (int i = 0; i < raw.length; i++) {
      final Object? item = raw[i];
      if (item is num) {
        bursts.add(item.round());
      } else {
        throw JsBridgeException.type(
          path: 'workoutModel.splitBurstReps[$i]',
          message: 'Expected num element in list, found ${item.runtimeType}: $item',
        );
      }
    }
    return bursts;
  }

  /// True if the set has both L and R sides tracked.
  bool isSideSet(SetEntry set) {
    final Object? result = _engine.call('workoutModel.isSideSet', <Object?>[set.toJson()]);
    return jsBool(result, 'workoutModel.isSideSet');
  }

  /// True if the set or either of its sides has completed work.
  bool hasCompletedWork(SetEntry set) {
    final Object? result = _engine.call(
      'workoutModel.hasCompletedWork',
      <Object?>[set.toJson()],
    );
    return jsBool(result, 'workoutModel.hasCompletedWork');
  }

  /// Actual completed volume (load x reps) including intensifiers.
  double completedVolumeOf(SetEntry set) {
    final Object? result = _engine.call(
      'workoutModel.completedVolumeOf',
      <Object?>[set.toJson()],
    );
    return jsDouble(result, 'workoutModel.completedVolumeOf');
  }

  /// Creates a per-side set from a plain set row.
  SetEntry makeSideSet([SetEntry? row]) {
    final Object? result = _engine.call(
      'workoutModel.makeSideSet',
      <Object?>[row?.toJson() ?? jsUndefined],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.makeSideSet'));
  }

  /// Resynchronizes parent scalar fields from L and R sides.
  SetEntry syncSideAggregate(SetEntry row) {
    final Object? result = _engine.call(
      'workoutModel.syncSideAggregate',
      <Object?>[row.toJson()],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.syncSideAggregate'));
  }

  /// Sets a field on one side ('L' or 'R') and resyncs aggregates.
  SetEntry setSideField(SetEntry row, String side, String field, Object? value) {
    final Object? result = _engine.call(
      'workoutModel.setSideField',
      <Object?>[row.toJson(), side, field, value],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.setSideField'));
  }

  /// Toggles the done status of one side and resyncs aggregates.
  SetEntry toggleSide(SetEntry row, String side) {
    final Object? result = _engine.call(
      'workoutModel.toggleSide',
      <Object?>[row.toJson(), side],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.toggleSide'));
  }

  /// Symmetrically adds a drop to both sides.
  SetEntry addSideDrop(SetEntry row, {num? pct}) {
    final Object? result = _engine.call(
      'workoutModel.addSideDrop',
      <Object?>[row.toJson(), pct ?? jsUndefined],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.addSideDrop'));
  }

  /// Symmetrically removes a drop from both sides by index.
  SetEntry removeSideDropAt(SetEntry row, int i) {
    final Object? result = _engine.call(
      'workoutModel.removeSideDropAt',
      <Object?>[row.toJson(), i],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.removeSideDropAt'));
  }

  /// Patches a drop on a single side and resyncs aggregates.
  SetEntry setSideDropAt(SetEntry row, String side, int i, Map<String, Object?> patch) {
    final Object? result = _engine.call(
      'workoutModel.setSideDropAt',
      <Object?>[row.toJson(), side, i, patch],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.setSideDropAt'));
  }

  /// Symmetrically adds a rest-pause cluster to both sides.
  SetEntry addSideCluster(SetEntry row, {num? restSec}) {
    final Object? result = _engine.call(
      'workoutModel.addSideCluster',
      <Object?>[row.toJson(), restSec ?? jsUndefined],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.addSideCluster'));
  }

  /// Symmetrically removes a rest-pause cluster from both sides by index.
  SetEntry removeSideClusterAt(SetEntry row, int i) {
    final Object? result = _engine.call(
      'workoutModel.removeSideClusterAt',
      <Object?>[row.toJson(), i],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.removeSideClusterAt'));
  }

  /// Sets reps on a single side cluster and resyncs aggregates.
  SetEntry setSideClusterAt(SetEntry row, String side, int i, num? r) {
    final Object? result = _engine.call(
      'workoutModel.setSideClusterAt',
      <Object?>[row.toJson(), side, i, r],
    );
    return SetEntry.fromJson(jsMap(result, 'workoutModel.setSideClusterAt'));
  }

  /// Normalizes a mode string to 'reps', 'time', or 'cardio'.
  String normalizeMode(Object? value, {String? fallback}) {
    final Object? result = _engine.call(
      'workoutModel.normalizeMode',
      <Object?>[value, fallback ?? jsUndefined],
    );
    return jsString(result, 'workoutModel.normalizeMode');
  }

  /// Resolves the exercise mode for a specific set.
  String modeForSet(SetEntry set, {Map<String, Object?>? target}) {
    final Object? result = _engine.call(
      'workoutModel.modeForSet',
      <Object?>[set.toJson(), target ?? jsUndefined],
    );
    return jsString(result, 'workoutModel.modeForSet');
  }

  /// Resolves the exercise mode for a workout entry (returns null on mixed modes).
  String? modeForEntry(WorkoutEntry entry, {String? fallback}) {
    final Object? result = _engine.call(
      'workoutModel.modeForEntry',
      <Object?>[entry.toJson(), fallback ?? jsUndefined],
    );
    return jsStringOrNull(result, 'workoutModel.modeForEntry');
  }
}

extension WorkoutModelJsAccess on JsEngineService {
  WorkoutModelJs get workoutModel => WorkoutModelJs(this);
}
