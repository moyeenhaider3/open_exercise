// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/models/progression_models.dart';
import 'package:open_exercise/core/js/modules/progression_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/routine.dart';
import 'package:open_exercise/core/models/set_entry.dart';
import 'package:open_exercise/core/models/workout.dart';

import '../parity_types.dart';

Map<String, ParityCall> progressionDispatch(JsEngineService engine) {
  final ProgressionJs prog = engine.progression;

  return <String, ParityCall>{
    'progression.isValidDeloadFactor': (List<Object?> args) {
      final Object? value = argAt(args, 0);
      return toPlainJson(prog.isValidDeloadFactor(value));
    },
    'progression.deloadFactorOf': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      return toPlainJson(prog.deloadFactorOf(cfg));
    },
    'progression.epley1RM': (List<Object?> args) {
      final num? weight = argAt(args, 0) as num?;
      final num? reps = argAt(args, 1) as num?;
      return toPlainJson(prog.epley1RM(weight, reps));
    },
    'progression.deloadTarget1RM': (List<Object?> args) {
      final num? weight = argAt(args, 0) as num?;
      final num? reps = argAt(args, 1) as num?;
      final num? factor = hasArg(args, 2) ? argAt(args, 2) as num? : null;
      final bool? perSide = hasArg(args, 3) ? argAt(args, 3) as bool? : null;
      return toPlainJson(prog.deloadTarget1RM(weight, reps, factor: factor, perSide: perSide));
    },
    'progression.defaultIncrement': (List<Object?> args) {
      final String? exId = argAt(args, 0) as String?;
      final String? unit = argAt(args, 1) as String?;
      return toPlainJson(prog.defaultIncrement(exId, unit));
    },
    'progression.weightIncrement': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      final String? unit = argAt(args, 1) as String?;
      return toPlainJson(prog.weightIncrement(cfg, unit));
    },
    'progression.policyFor': (List<Object?> args) {
      final RoutineExercise? cfg = hasArg(args, 0) && argAt(args, 0) != null
          ? RoutineExercise.fromJson(jsonMapArg(args, 0))
          : null;
      final Routine? routine = hasArg(args, 1) && argAt(args, 1) != null
          ? Routine.fromJson(jsonMapArg(args, 1))
          : null;
      final String? mode = hasArg(args, 2) ? argAt(args, 2) as String? : null;
      return toPlainJson(prog.policyFor(cfg, routine, mode));
    },
    'progression.snapWeight': (List<Object?> args) {
      final num v = argAt(args, 0) as num;
      final num? step = argAt(args, 1) as num?;
      return toPlainJson(prog.snapWeight(v, step));
    },
    'progression.addStep': (List<Object?> args) {
      final num? w = argAt(args, 0) as num?;
      final num step = argAt(args, 1) as num;
      final num? inc = argAt(args, 2) as num?;
      return toPlainJson(prog.addStep(w, step, inc));
    },
    'progression.stepWeight': (List<Object?> args) {
      final num? value = argAt(args, 0) as num?;
      final num step = argAt(args, 1) as num;
      final num direction = argAt(args, 2) as num;
      return toPlainJson(prog.stepWeight(value, step, direction));
    },
    'progression.deloadTo': (List<Object?> args) {
      final num cur = argAt(args, 0) as num;
      final num step = argAt(args, 1) as num;
      final num? factor = hasArg(args, 2) ? argAt(args, 2) as num? : null;
      return toPlainJson(prog.deloadTo(cur, step, factor: factor));
    },
    'progression.selectDeloadCandidate': (List<Object?> args) {
      final DeloadCandidateQuery q = DeloadCandidateQuery.fromJson(jsonMapArg(args, 0));
      return toPlainJson(prog.selectDeloadCandidate(q));
    },
    'progression.readSession': (List<Object?> args) {
      final WorkoutEntry entry = WorkoutEntry.fromJson(jsonMapArg(args, 0));
      final Object? fallback = hasArg(args, 1) ? argAt(args, 1) : null;
      return toPlainJson(prog.readSession(entry, fallback));
    },
    'progression.sessionsFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      final Object? fallback = hasArg(args, 2) ? argAt(args, 2) : null;
      return toPlainJson(prog.sessionsFor(s, exId, fallback));
    },
    'progression.stallCount': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<SessionSummary> sessions = rawList
          .map((Object? item) => SessionSummary.fromJson(item as Map<String, Object?>))
          .toList();
      final String policy = argAt(args, 1) as String;
      return toPlainJson(prog.stallCount(sessions, policy));
    },
    'progression.nextPrescription': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final RoutineExercise cfg = RoutineExercise.fromJson(jsonMapArg(args, 1));
      final Routine? routine = hasArg(args, 2) && argAt(args, 2) != null
          ? Routine.fromJson(jsonMapArg(args, 2))
          : null;
      return toPlainJson(prog.nextPrescription(s, cfg, routine));
    },
    'progression.applyPrescription': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<SetEntry> sets = rawList
          .map((Object? item) => SetEntry.fromJson(item as Map<String, Object?>))
          .toList();
      final Prescription? p = hasArg(args, 1) && argAt(args, 1) != null
          ? Prescription.fromJson(jsonMapArg(args, 1))
          : null;
      final num? step = hasArg(args, 2) ? argAt(args, 2) as num? : null;
      return toPlainJson(prog.applyPrescription(sets, p, step: step));
    },
  };
}
