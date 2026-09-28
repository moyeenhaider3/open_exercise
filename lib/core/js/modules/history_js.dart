// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `history.js` module.
///
/// Handles exercise configuration, effort rating scales, superset grouping,
/// routine resolution, set building, weight cascading, warm-up ramps, and volume metrics.
///
/// NOTE: Presentation label helpers (`setLabel`, `exLine`, and `fmtSec`) are
/// intentionally NOT bridged here. Those functions produce formatted strings dependent
/// on openGym's `i18n.js` / `i18n-core.js` and would produce only English output.
/// In this application, Phase 3 and Phase 8 own all user-facing presentation strings
/// in Dart with proper localization. This facade provides all the underlying numeric
/// data and domain structures required to render those labels.
library;

import '../../models/bodyweight_entry.dart';
import '../../models/gym_state.dart';
import '../../models/routine.dart';
import '../../models/set_entry.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/history_models.dart';

final class HistoryJs {
  const HistoryJs(this._engine);

  final JsEngineService _engine;

  /// Logging mode ('reps', 'time', or 'cardio') for an exercise config.
  String modeOf(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'history.modeOf',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsString(result, 'history.modeOf');
  }

  /// True if the exercise is logged in time mode.
  bool isTimed(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'history.isTimed',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsBool(result, 'history.isTimed');
  }

  /// True if the exercise is bodyweight.
  bool isBw(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'history.isBw',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsBool(result, 'history.isBw');
  }

  /// True if the exercise is performed per-side (unilateral).
  bool isPerSide(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'history.isPerSide',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsBool(result, 'history.isPerSide');
  }

  /// Reps for one side (total reps divided by 2).
  double sideReps(num? reps) {
    final Object? result = _engine.call('history.sideReps', <Object?>[reps]);
    return jsDouble(result, 'history.sideReps');
  }

  /// Repetition step (2 for per-side, 1 for bilateral).
  int repStep(RoutineExercise? cfg) {
    final Object? result = _engine.call(
      'history.repStep',
      <Object?>[cfg?.toJson() ?? jsUndefined],
    );
    return jsInt(result, 'history.repStep');
  }

  /// Steps an effort rating cell up or down (+1 or -1).
  double? stepEffort(String kind, num? cur, num dir) {
    final Object? result = _engine.call('history.stepEffort', <Object?>[kind, cur, dir]);
    return jsDoubleOrNull(result, 'history.stepEffort');
  }

  /// Caps a typed effort value against its scale maximum.
  num? capEffort(String kind, num? v) {
    final Object? result = _engine.call('history.capEffort', <Object?>[kind, v]);
    if (result == null) return null;
    if (result is num) return result;
    return jsDoubleOrNull(result, 'history.capEffort');
  }

  /// Determines which effort rating scale a profile logs ('rir', 'rpe', or 'none').
  String effortOf(GymState? s) {
    final Object? result = _engine.call(
      'history.effortOf',
      <Object?>[s?.toJson() ?? jsUndefined],
    );
    return jsString(result, 'history.effortOf');
  }

  /// Default configuration for an exercise newly added to a routine.
  RoutineExercise defaultConfig(String id, [String? mode]) {
    final Object? result = _engine.call(
      'history.defaultConfig',
      <Object?>[id, mode ?? jsUndefined],
    );
    return RoutineExercise.fromJson(jsMap(result, 'history.defaultConfig'));
  }

  /// Cleans up superset IDs with no adjacent partner.
  List<RoutineExercise> cleanupSg(List<RoutineExercise> ex) {
    final Object? result = _engine.call(
      'history.cleanupSg',
      <Object?>[ex.map((RoutineExercise e) => e.toJson()).toList()],
    );
    return jsListOf<RoutineExercise>(result, 'history.cleanupSg', RoutineExercise.fromJson);
  }

  /// Cleans up superset groups in a list of workout entries.
  List<WorkoutEntry> cleanupSgWorkoutEntries(List<WorkoutEntry> ex) {
    final Object? result = _engine.call(
      'history.cleanupSg',
      <Object?>[ex.map((WorkoutEntry e) => e.toJson()).toList()],
    );
    return jsListOf<WorkoutEntry>(result, 'history.cleanupSg', WorkoutEntry.fromJson);
  }

  /// Pairs two adjacent exercises into a superset.
  List<RoutineExercise> pairAdjacent(
    List<RoutineExercise> items,
    int first,
    int second, [
    String? groupId,
  ]) {
    final Object? result = _engine.call(
      'history.pairAdjacent',
      <Object?>[
        items.map((RoutineExercise e) => e.toJson()).toList(),
        first,
        second,
        groupId ?? jsUndefined,
      ],
    );
    return jsListOf<RoutineExercise>(result, 'history.pairAdjacent', RoutineExercise.fromJson);
  }

  /// Pairs two adjacent workout entries into a superset.
  List<WorkoutEntry> pairAdjacentWorkoutEntries(
    List<WorkoutEntry> items,
    int first,
    int second, [
    String? groupId,
  ]) {
    final Object? result = _engine.call(
      'history.pairAdjacent',
      <Object?>[
        items.map((WorkoutEntry e) => e.toJson()).toList(),
        first,
        second,
        groupId ?? jsUndefined,
      ],
    );
    return jsListOf<WorkoutEntry>(result, 'history.pairAdjacent', WorkoutEntry.fromJson);
  }

  /// Unpairs an exercise from its superset.
  List<RoutineExercise> unpairSuperset(List<RoutineExercise> items, int idx) {
    final Object? result = _engine.call(
      'history.unpairSuperset',
      <Object?>[
        items.map((RoutineExercise e) => e.toJson()).toList(),
        idx,
      ],
    );
    return jsListOf<RoutineExercise>(result, 'history.unpairSuperset', RoutineExercise.fromJson);
  }

  /// Unpairs a workout entry from its superset.
  List<WorkoutEntry> unpairSupersetWorkoutEntries(List<WorkoutEntry> items, int idx) {
    final Object? result = _engine.call(
      'history.unpairSuperset',
      <Object?>[
        items.map((WorkoutEntry e) => e.toJson()).toList(),
        idx,
      ],
    );
    return jsListOf<WorkoutEntry>(result, 'history.unpairSuperset', WorkoutEntry.fromJson);
  }

  /// True if a completed entry is excluded from progression.
  bool entryExcluded(Workout? w, WorkoutEntry? entry) {
    final Object? result = _engine.call(
      'history.entryExcluded',
      <Object?>[w?.toJson() ?? jsUndefined, entry?.toJson() ?? jsUndefined],
    );
    return jsBool(result, 'history.entryExcluded');
  }

  /// Looks up the most recent completed counting entry for an exercise.
  WorkoutEntry? lastEntryFor(GymState s, String exId) {
    final Object? result = _engine.call(
      'history.lastEntryFor',
      <Object?>[s.toJson(), exId],
    );
    if (result == null) return null;
    return WorkoutEntry.fromJson(jsMap(result, 'history.lastEntryFor'));
  }

  /// Most recent session note pinned for an exercise.
  PinnedNote? pinnedNoteFor(GymState s, String exId) {
    final Object? result = _engine.call(
      'history.pinnedNoteFor',
      <Object?>[s.toJson(), exId],
    );
    if (result == null) return null;
    return PinnedNote.fromJson(jsMap(result, 'history.pinnedNoteFor'));
  }

  /// Standing note for an exercise.
  String? exNoteFor(GymState s, String exId) {
    final Object? result = _engine.call(
      'history.exNoteFor',
      <Object?>[s.toJson(), exId],
    );
    return jsStringOrNull(result, 'history.exNoteFor');
  }

  /// Seeds a freestyle exercise configuration from the last performed session.
  RoutineExercise freestyleConfig(GymState s, RoutineExercise cfg) {
    final Object? result = _engine.call(
      'history.freestyleConfig',
      <Object?>[s.toJson(), cfg.toJson()],
    );
    return RoutineExercise.fromJson(jsMap(result, 'history.freestyleConfig'));
  }

  /// All-time best load logged for an exercise.
  double bestWeightFor(GymState s, String exId) {
    final Object? result = _engine.call(
      'history.bestWeightFor',
      <Object?>[s.toJson(), exId],
    );
    return jsDouble(result, 'history.bestWeightFor');
  }

  /// Routine IDs scheduled for a date in merge order.
  List<String> effectiveRoutineIds(GymState s, String iso) {
    final Object? result = _engine.call(
      'history.effectiveRoutineIds',
      <Object?>[s.toJson(), iso],
    );
    return jsStringList(result, 'history.effectiveRoutineIds');
  }

  /// Routines scheduled for a date in merge order.
  List<Routine> effectiveRoutines(GymState s, String iso) {
    final Object? result = _engine.call(
      'history.effectiveRoutines',
      <Object?>[s.toJson(), iso],
    );
    return jsListOf<Routine>(result, 'history.effectiveRoutines', Routine.fromJson);
  }

  /// Primary routine ID scheduled for a date.
  String? effectiveRoutineId(GymState s, String iso) {
    final Object? result = _engine.call(
      'history.effectiveRoutineId',
      <Object?>[s.toJson(), iso],
    );
    return jsStringOrNull(result, 'history.effectiveRoutineId');
  }

  /// Primary routine scheduled for a date.
  Routine? effectiveRoutine(GymState s, String iso) {
    final Object? result = _engine.call(
      'history.effectiveRoutine',
      <Object?>[s.toJson(), iso],
    );
    if (result == null) return null;
    return Routine.fromJson(jsMap(result, 'history.effectiveRoutine'));
  }

  /// Next date that has scheduled exercises, looking forward from [iso].
  TrainingDay? nextTrainingDay(GymState s, String iso) {
    final Object? result = _engine.call(
      'history.nextTrainingDay',
      <Object?>[s.toJson(), iso],
    );
    if (result == null) return null;
    return TrainingDay.fromJson(jsMap(result, 'history.nextTrainingDay'));
  }

  /// Builds the initial set rows for an exercise starting a session.
  List<SetEntry> buildSets(GymState s, RoutineExercise cfg, {BuildSetsOptions? options}) {
    final Object? result = _engine.call(
      'history.buildSets',
      <Object?>[s.toJson(), cfg.toJson(), options?.toJson() ?? jsUndefined],
    );
    return jsListOf<SetEntry>(result, 'history.buildSets', SetEntry.fromJson);
  }

  /// Applies planned intensifiers (drop-sets or rest-pause clusters) to work sets.
  List<SetEntry> applyIntensifierPlan(List<SetEntry> sets, RoutineExercise cfg) {
    final Object? result = _engine.call(
      'history.applyIntensifierPlan',
      <Object?>[sets.map((SetEntry s) => s.toJson()).toList(), cfg.toJson()],
    );
    return jsListOf<SetEntry>(result, 'history.applyIntensifierPlan', SetEntry.fromJson);
  }

  /// Total completed workout volume (excluding warm-up rows).
  double workoutVolume(Workout w) {
    final Object? result = _engine.call('history.workoutVolume', <Object?>[w.toJson()]);
    return jsDouble(result, 'history.workoutVolume');
  }

  /// Number of completion units for a set (2 for unilateral, 1 otherwise).
  int setUnits(SetEntry s) {
    final Object? result = _engine.call('history.setUnits', <Object?>[s.toJson()]);
    return jsInt(result, 'history.setUnits');
  }

  /// Number of completed units for a set (0..2 for unilateral, 0..1 otherwise).
  int doneUnits(SetEntry s) {
    final Object? result = _engine.call('history.doneUnits', <Object?>[s.toJson()]);
    return jsInt(result, 'history.doneUnits');
  }

  /// Total completion units across all entries.
  int setUnitsTotal(List<WorkoutEntry> entries) {
    final Object? result = _engine.call(
      'history.setUnitsTotal',
      <Object?>[entries.map((WorkoutEntry e) => e.toJson()).toList()],
    );
    return jsInt(result, 'history.setUnitsTotal');
  }

  /// Number of completed set units in a finished workout.
  int setsDone(Workout w) {
    final Object? result = _engine.call('history.setsDone', <Object?>[w.toJson()]);
    return jsInt(result, 'history.setsDone');
  }

  /// Number of completed set units in an active workout.
  int setsDoneActive(Workout a) {
    final Object? result = _engine.call('history.setsDoneActive', <Object?>[a.toJson()]);
    return jsInt(result, 'history.setsDoneActive');
  }

  /// Most recent bodyweight log entry.
  BodyweightEntry? lastBW(GymState s) {
    final Object? result = _engine.call('history.lastBW', <Object?>[s.toJson()]);
    if (result == null) return null;
    return BodyweightEntry.fromJson(jsMap(result, 'history.lastBW'));
  }

  /// Groups consecutive items sharing a superset ID into index lists.
  List<List<int>> supersetUnits(List<Object?> items) {
    final Object? result = _engine.call('history.supersetUnits', <Object?>[items]);
    final List<Object?> rawUnits = jsList(result, 'history.supersetUnits');
    final List<List<int>> units = <List<int>>[];
    for (int i = 0; i < rawUnits.length; i++) {
      final List<Object?> rawGroup = jsList(rawUnits[i], 'history.supersetUnits[$i]');
      final List<int> group = <int>[];
      for (final Object? item in rawGroup) {
        if (item is num) {
          group.add(item.toInt());
        }
      }
      units.add(group);
    }
    return units;
  }

  /// Moves a complete superset group of exercises by direction (-1 or 1).
  List<RoutineExercise>? moveSupersetUnit(
    List<RoutineExercise> items,
    int index,
    int direction,
  ) {
    final Object? result = _engine.call(
      'history.moveSupersetUnit',
      <Object?>[
        items.map((RoutineExercise e) => e.toJson()).toList(),
        index,
        direction,
      ],
    );
    if (result == null) return null;
    return jsListOf<RoutineExercise>(result, 'history.moveSupersetUnit', RoutineExercise.fromJson);
  }

  /// Finds the superset group containing index [idx].
  List<int> unitOf(List<List<int>> units, int idx) {
    final Object? result = _engine.call('history.unitOf', <Object?>[units, idx]);
    final List<Object?> raw = jsList(result, 'history.unitOf');
    return raw.map((Object? x) => (x as num).toInt()).toList();
  }

  /// Number of consecutive training weeks.
  int streakWeeks(GymState s) {
    final Object? result = _engine.call('history.streakWeeks', <Object?>[s.toJson()]);
    return jsInt(result, 'history.streakWeeks');
  }

  /// Cascades a weight change forward to subsequent uncompleted rows of the same phase.
  List<SetEntry> cascadeWeight(List<SetEntry> rows, int from, num? value) {
    final Object? result = _engine.call(
      'history.cascadeWeight',
      <Object?>[rows.map((SetEntry s) => s.toJson()).toList(), from, value],
    );
    return jsListOf<SetEntry>(result, 'history.cascadeWeight', SetEntry.fromJson);
  }

  /// Recomputes warm-up rows to ramp toward the working weight.
  List<SetEntry> rerampWarmups(List<SetEntry> rows, {num? step}) {
    final Object? result = _engine.call(
      'history.rerampWarmups',
      <Object?>[rows.map((SetEntry s) => s.toJson()).toList(), step ?? jsUndefined],
    );
    return jsListOf<SetEntry>(result, 'history.rerampWarmups', SetEntry.fromJson);
  }

  /// Inserts a warm-up row ramping toward the work weight.
  List<SetEntry> insertWarmupRow(
    List<SetEntry> rows,
    String mode,
    RoutineExercise target, {
    num? step,
  }) {
    final Object? result = _engine.call(
      'history.insertWarmupRow',
      <Object?>[
        rows.map((SetEntry s) => s.toJson()).toList(),
        mode,
        target.toJson(),
        step ?? jsUndefined,
      ],
    );
    return jsListOf<SetEntry>(result, 'history.insertWarmupRow', SetEntry.fromJson);
  }

  /// Removes the row at index [i], never leaving fewer than one row.
  List<SetEntry> removeRowAt(List<SetEntry> rows, int i) {
    final Object? result = _engine.call(
      'history.removeRowAt',
      <Object?>[rows.map((SetEntry s) => s.toJson()).toList(), i],
    );
    return jsListOf<SetEntry>(result, 'history.removeRowAt', SetEntry.fromJson);
  }

  /// Total completed work sets (excluding warm-ups) across all entries in a workout.
  int workSetsDone(Workout w) {
    final Object? result = _engine.call('history.workSetsDone', <Object?>[w.toJson()]);
    return jsInt(result, 'history.workSetsDone');
  }

  /// Completed work rows matching the entry's authoritative mode.
  List<SetEntry> metricRowsForEntry(WorkoutEntry entry, [String? mode]) {
    final Object? result = _engine.call(
      'history.metricRowsForEntry',
      <Object?>[entry.toJson(), mode ?? jsUndefined],
    );
    return jsListOf<SetEntry>(result, 'history.metricRowsForEntry', SetEntry.fromJson);
  }

  /// The authoritative metric mode for a workout entry.
  String? metricModeForEntry(WorkoutEntry entry, {String? fallback}) {
    final Object? result = _engine.call(
      'history.metricModeForEntry',
      <Object?>[entry.toJson(), fallback ?? jsUndefined],
    );
    return jsStringOrNull(result, 'history.metricModeForEntry');
  }

  /// Best load from completed work rows in an entry.
  double bestWeightForEntry([WorkoutEntry? entry]) {
    final Object? result = _engine.call(
      'history.bestWeightForEntry',
      <Object?>[entry?.toJson() ?? jsUndefined],
    );
    return jsDouble(result, 'history.bestWeightForEntry');
  }

  /// Rating scale definitions for RIR and RPE.
  Map<String, EffortScale> get effort {
    final Map<String, Object?> raw = jsMap(_engine.read('history.EFFORT'), 'history.EFFORT');
    return raw.map(
      (String k, Object? v) => MapEntry<String, EffortScale>(
        k,
        EffortScale.fromJson(jsMap(v, 'history.EFFORT["$k"]')),
      ),
    );
  }

  /// Maximum allowed character length for notes (500).
  int get noteMax => jsInt(_engine.read('history.NOTE_MAX'), 'history.NOTE_MAX');

  /// Maximum planned warm-up sets allowed per exercise (5).
  int get maxPlannedWarmups =>
      jsInt(_engine.read('history.MAX_PLANNED_WARMUPS'), 'history.MAX_PLANNED_WARMUPS');
}

extension HistoryJsAccess on JsEngineService {
  HistoryJs get history => HistoryJs(this);
}
