// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/format/workout_controls.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/history_models.dart';
import '../../../core/js/models/phase3_models.dart';
import '../../../core/js/models/progression_models.dart';
import '../../../core/js/modules/finish_workout_js.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/progression_js.dart';
import '../../../core/js/modules/session_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/set_entry.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../data/active_exercise_swap.dart';
import '../data/active_workout_order.dart';
import '../data/superset_flow.dart';
import 'workout_event.dart';
import 'workout_state.dart';

/// App-scoped BLoC managing workout lifecycle and session-level mutations.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Domain math, progression, and workout completion delegate exclusively to
/// QuickJS/JSC via [JsEngineService] (JS-04).
///
/// Per D-02, work and rest countdown timers are omitted and moved to Phase 5.
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        _engine = engine,
        super(_stateFromGym(gymState.state, engine)) {
    on<WorkoutEvent>(_onEvent, transformer: _sequential<WorkoutEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(WorkoutGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  StreamSubscription<GymState>? _subscription;

  List<int> _progressHighWater = <int>[];
  int _seq = 0;

  /// High-water set index progress tracking for superset flow and progression (used by 03-10).
  List<int> get progressHighWater => List<int>.unmodifiable(_progressHighWater);

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  static WorkoutState _stateFromGym(
    GymState s,
    JsEngineService engine, [
    WorkoutSignal? signal,
    int seq = 0,
  ]) {
    final Workout? active = s.active;
    if (active == null) {
      return WorkoutNone(signal: signal, seq: seq);
    }
    final List<WorkoutEntry> entries = active.entries ?? const <WorkoutEntry>[];
    final List<List<int>> units = engine.history.supersetUnits(entries);
    final int cur = entries.isEmpty ? 0 : (active.cur ?? 0).clamp(0, entries.length - 1);
    final List<int> currentUnit = entries.isEmpty ? const <int>[] : engine.history.unitOf(units, cur);
    final int unitIdx = units.indexWhere((List<int> u) => u.contains(cur));
    final String view = active.workoutView ?? s.workoutView ?? 'cards';
    final int setsDone = engine.history.setsDoneActive(active);
    final int setsTotal = engine.history.setUnitsTotal(entries);
    final WorkoutControlsView wc = workoutControls(s);
    return WorkoutRunning(
      active: active,
      units: units,
      cur: cur,
      currentUnit: currentUnit,
      unitIdx: unitIdx >= 0 ? unitIdx : 0,
      view: view,
      setsDone: setsDone,
      setsTotal: setsTotal,
      wc: wc,
      signal: signal,
      seq: seq,
    );
  }

  void _emitSignal(WorkoutSignal sig, Emitter<WorkoutState> emit) {
    _seq++;
    emit(_stateFromGym(_gymState.state, _engine, sig, _seq));
  }

  Future<void> _onEvent(WorkoutEvent event, Emitter<WorkoutState> emit) async {
    switch (event) {
      case WorkoutGymStateChanged(:final GymState state):
        _onGymStateChanged(state, emit);
      case WorkoutStartRequested():
        await _onStartRequested(event, emit);
      case WorkoutFinishRequested():
        _onFinishRequested(emit);
      case WorkoutFinishConfirmed():
        await _onFinishConfirmed(emit);
      case WorkoutDiscarded():
        await _onDiscarded();
      case WorkoutRenamed(:final String name):
        await _onRenamed(name);
      case WorkoutSessionNoteChanged(:final String text):
        await _onSessionNoteChanged(text);
      case WorkoutExerciseNoteSaved():
        await _onExerciseNoteSaved(event);
      case WorkoutViewChanged(:final String view):
        await _onViewChanged(view);
      case WorkoutUnitFocused(:final int firstIdx):
        await _onUnitFocused(firstIdx);
      case WorkoutUnitNavigated(:final int direction):
        await _onUnitNavigated(direction);
      case WorkoutUnitMoved(:final int at, :final int direction):
        await _onUnitMoved(at, direction);
      case WorkoutPaired(:final int first, :final int second):
        await _onPaired(first, second);
      case WorkoutUnpaired(:final int idx):
        await _onUnpaired(idx);
      case WorkoutExerciseAdded():
        await _onExerciseAdded(event, emit);
      case WorkoutExerciseSwapped():
        await _onExerciseSwapped(event);
      case WorkoutExerciseRemoved(:final int idx):
        await _onExerciseRemoved(idx);
      case WorkoutRoutineAddedToSession(:final String routineId):
        await _onRoutineAddedToSession(routineId, emit);
    }
  }

  void _onGymStateChanged(GymState state, Emitter<WorkoutState> emit) {
    emit(_stateFromGym(state, _engine, null, _seq));
  }

  /// Begins a workout session.
  /// Ported from ../openGym/frontend/src/sheets.jsx:1804-1832 beginWorkout and BwSheet.save (200-216).
  /// Countdown timers are omitted per D-02.
  Future<void> _onStartRequested(
    WorkoutStartRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    _progressHighWater = <int>[];
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String today = todayIso();
    // BwSheet.save rounds bodyweight to 1 decimal place: Math.round(v * 10) / 10
    final num? loggedBw =
        event.bw != null ? (event.bw! * 10).round() / 10.0 : null;

    await _gymState.mutate((GymState s) {
      final List<BodyweightEntry> nextBw = s.bodyweight != null
          ? List<BodyweightEntry>.from(s.bodyweight!)
          : <BodyweightEntry>[];
      if (loggedBw != null) {
        final int existingIdx = nextBw.indexWhere((BodyweightEntry b) => b.d == today);
        final BodyweightEntry entry = BodyweightEntry(
          d: today,
          w: loggedBw,
          t: now,
        );
        if (existingIdx >= 0) {
          nextBw[existingIdx] = entry;
        } else {
          nextBw.add(entry);
        }
        nextBw.sort((BodyweightEntry a, BodyweightEntry b) => (a.d ?? '').compareTo(b.d ?? ''));
      }

      final CombinedSession combined =
          _engine.sessionMerge.buildCombinedEntries(s, event.routineIds);
      final List<String> names = (combined.routines ?? const <Routine>[])
          .map((Routine r) => r.name ?? '')
          .where((String n) => n.isNotEmpty)
          .toList();
      final String sessionName = event.routineIds.isEmpty
          ? t('Freestyle')
          : (_engine.sessionMerge.deriveSessionName(names) ?? t('Freestyle'));

      final Workout active = Workout(
        id: uid(),
        d: today,
        start: now,
        routineIds: event.routineIds,
        name: sessionName,
        bw: loggedBw,
        cur: 0,
        entries: combined.entries ?? const <WorkoutEntry>[],
      ).withExtraFields(<String, Object?>{
        'workoutView': s.workoutView ?? 'cards',
      });

      return s.copyWith(
        bodyweight: loggedBw != null ? nextBw : s.bodyweight,
        active: active,
      );
    });

    _emitSignal(const WorkoutStartedSignal(), emit);
  }

  /// Triggers verification check before finishing workout.
  /// Ported from ../openGym/frontend/src/sheets.jsx:2179 finishWorkout.
  void _onFinishRequested(Emitter<WorkoutState> emit) {
    final Workout? active = _gymState.state.active;
    if (active == null) return;
    final int done = _engine.history.setsDoneActive(active);
    final int total = _engine.history.setUnitsTotal(active.entries ?? const <WorkoutEntry>[]);
    _emitSignal(WorkoutFinishCheckSignal(done: done, total: total), emit);
  }

  /// Commits workout completion through openGym's JS bridge.
  /// Ported from ../openGym/frontend/src/sheets.jsx:2200-2228 doFinishWorkout.
  /// Note: autoBackupNow is deferred to Phase 8 and audio beeps to Phase 5 (D-02).
  Future<void> _onFinishConfirmed(Emitter<WorkoutState> emit) async {
    final GymState s = _gymState.state;
    if (s.active == null) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final FinishResult result = _engine.finish.completeWorkout(s, now);
    _progressHighWater = <int>[];

    await _gymState.mutate((GymState st) {
      final List<Workout> nextWorkouts = List<Workout>.from(st.workouts ?? const <Workout>[]);
      nextWorkouts.add(result.workout);
      return st.copyWith(
        workouts: nextWorkouts,
        exWeights: result.exWeights,
        active: null,
      );
    });

    _emitSignal(WorkoutFinishedSignal(result), emit);
  }

  /// Discards the active workout without saving to history.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:982.
  Future<void> _onDiscarded() async {
    _progressHighWater = <int>[];
    await _gymState.mutate((GymState s) => s.copyWith(active: null));
  }

  /// Renames the active workout session.
  /// Ported from ../openGym/frontend/src/sheets.jsx:2105-2130 RenameWorkout.save.
  Future<void> _onRenamed(String name) async {
    final String trimmed = name.trim();
    final String newName = trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed;
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null) return s;
      final Workout next = active.copyWith(name: newName).withExtraFields(<String, Object?>{
        'customName': true,
      });
      return s.copyWith(active: next);
    });
  }

  /// Updates the workout-level session note.
  /// Ported from ../openGym/frontend/src/sheets.jsx:2078-2100 SessionNote.save.
  Future<void> _onSessionNoteChanged(String text) async {
    final int maxLen = _engine.history.noteMax;
    final String trimmed = text.trim();
    final String? noteVal =
        trimmed.isEmpty ? null : (trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed);
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null) return s;
      final Workout next;
      if (noteVal == null) {
        next = active.withExtraFields(const <String, Object?>{}, remove: const <String>['note']);
      } else {
        next = active.withExtraFields(<String, Object?>{'note': noteVal});
      }
      return s.copyWith(active: next);
    });
  }

  /// Saves today's exercise note, note pinning, and standing exercise note.
  /// Ported from ../openGym/frontend/src/sheets.jsx:2019-2050 ExerciseNote.save.
  Future<void> _onExerciseNoteSaved(WorkoutExerciseNoteSaved event) async {
    final int maxLen = _engine.history.noteMax;
    final String todayNote = event.today.trim();
    final String? cappedToday =
        todayNote.isEmpty ? null : (todayNote.length > maxLen ? todayNote.substring(0, maxLen) : todayNote);
    final String standingNote = event.standing.trim();
    final String? cappedStanding = standingNote.isEmpty
        ? null
        : (standingNote.length > maxLen ? standingNote.substring(0, maxLen) : standingNote);

    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      final String? exId = entry.id;
      if (exId == null) return s;

      final WorkoutEntry updatedEntry;
      if (cappedToday == null) {
        updatedEntry = entry.withExtraFields(
          const <String, Object?>{},
          remove: const <String>['note', 'notePin'],
        );
      } else {
        final Map<String, Object?> setFields = <String, Object?>{'note': cappedToday};
        final List<String> removeFields = <String>[];
        if (event.pin) {
          setFields['notePin'] = true;
        } else {
          removeFields.add('notePin');
        }
        updatedEntry = entry.withExtraFields(setFields, remove: removeFields);
      }
      entries[event.entryIdx] = updatedEntry;

      final Map<String, String> nextExNotes =
          Map<String, String>.from(s.exNotes ?? const <String, String>{});
      if (cappedStanding == null) {
        nextExNotes.remove(exId);
      } else {
        nextExNotes[exId] = cappedStanding;
      }

      return s.copyWith(
        active: active.copyWith(entries: entries),
        exNotes: nextExNotes,
      );
    });
  }

  /// Updates workout layout view mode ('cards', 'list', 'compact').
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:735 setWorkoutView.
  Future<void> _onViewChanged(String view) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      return s.copyWith(
        workoutView: view,
        active: active?.withExtraFields(<String, Object?>{'workoutView': view}),
      );
    });
  }

  /// Focuses a specific unit index.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:729 focusUnit.
  Future<void> _onUnitFocused(int firstIdx) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null || active.entries!.isEmpty) return s;
      final int clamped = firstIdx.clamp(0, active.entries!.length - 1);
      final String curView = active.workoutView ?? s.workoutView ?? 'cards';
      final bool switchCards = curView == 'list';
      Workout next = active.copyWith(cur: clamped);
      if (switchCards) {
        next = next.withExtraFields(<String, Object?>{'workoutView': 'cards'});
      }
      return s.copyWith(
        workoutView: switchCards ? 'cards' : s.workoutView,
        active: next,
      );
    });
  }

  /// Navigates to previous (-1) or next (+1) unit.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:716 navigateUnit.
  Future<void> _onUnitNavigated(int direction) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null || active.entries!.isEmpty) return s;
      final List<WorkoutEntry> entries = active.entries!;
      final List<List<int>> units = _engine.history.supersetUnits(entries);
      final int cur = (active.cur ?? 0).clamp(0, entries.length - 1);
      final int unitIdx = units.indexWhere((List<int> u) => u.contains(cur));
      if (unitIdx < 0) return s;
      final int targetIdx = unitIdx + direction;
      if (targetIdx >= 0 && targetIdx < units.length && units[targetIdx].isNotEmpty) {
        return s.copyWith(active: active.copyWith(cur: units[targetIdx].first));
      }
      return s;
    });
  }

  /// Moves a superset unit up (-1) or down (+1) in workout order.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:673 moveUnitAt.
  Future<void> _onUnitMoved(int at, int direction) async {
    final Workout? active = _gymState.state.active;
    if (active == null || active.entries == null || active.entries!.isEmpty) return;
    final moveResult = moveActiveWorkoutUnit(active, at, direction, _engine.history);
    if (moveResult == null) return;

    if (_progressHighWater.isNotEmpty) {
      final List<int> remapped = List<int>.filled(moveResult.indices.length, 0);
      for (int i = 0; i < moveResult.indices.length; i++) {
        final int oldIdx = moveResult.indices[i];
        if (oldIdx < _progressHighWater.length) {
          remapped[i] = _progressHighWater[oldIdx];
        }
      }
      _progressHighWater = remapped;
    }

    await _gymState.mutate((GymState s) => s.copyWith(active: moveResult.active));
  }

  /// Pairs two adjacent exercises into a superset.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:663 pairAt.
  Future<void> _onPaired(int first, int second) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      final List<WorkoutEntry> paired = _engine.history.pairAdjacentWorkoutEntries(
        active.entries!,
        first,
        second,
      );
      return s.copyWith(active: active.copyWith(entries: paired));
    });
  }

  /// Unpairs an exercise from its superset group.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:666 unpairAt.
  Future<void> _onUnpaired(int idx) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      final List<WorkoutEntry> unpaired = _engine.history.unpairSupersetWorkoutEntries(
        active.entries!,
        idx,
      );
      return s.copyWith(active: active.copyWith(entries: unpaired));
    });
  }

  /// Adds an exercise to the active workout session.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:1066-1096.
  Future<void> _onExerciseAdded(
    WorkoutExerciseAdded event,
    Emitter<WorkoutState> emit,
  ) async {
    final GymState s = _gymState.state;
    final Workout? active = s.active;
    if (active == null) return;

    final List<WorkoutEntry> entries =
        active.entries != null ? List<WorkoutEntry>.from(active.entries!) : <WorkoutEntry>[];
    final int cur = (active.cur ?? 0).clamp(0, entries.isEmpty ? 0 : entries.length - 1);
    final String? rid = entries.isNotEmpty && cur < entries.length ? entries[cur].rid : null;
    final Routine? routine =
        rid != null ? s.routines?.firstWhereOrNull((Routine r) => r.id == rid) : null;

    RoutineExercise cfg = event.cfg;
    if (routine == null) {
      cfg = _engine.history.freestyleConfig(s, cfg);
    }
    List<SetEntry> sets = _engine.history.buildSets(s, cfg);
    if (routine != null) {
      final Prescription p = _engine.progression.nextPrescription(s, cfg, routine);
      sets = _engine.progression.applyPrescription(sets, p);
    }
    sets = _engine.history.applyIntensifierPlan(sets, cfg);

    final WorkoutEntry newEntry = WorkoutEntry(
      id: event.exId,
      rid: rid,
      sets: sets,
    ).withExtraFields(<String, Object?>{'target': cfg.toJson()});

    final List<List<int>> units = _engine.history.supersetUnits(entries);
    final int insertAt = insertionIndexAfterCurrentUnit(units, cur, entries.length);
    entries.insert(insertAt, newEntry);

    if (insertAt <= _progressHighWater.length) {
      _progressHighWater.insert(insertAt, 0);
    } else {
      _progressHighWater.add(0);
    }

    await _gymState.mutate(
      (GymState st) => st.copyWith(active: active.copyWith(entries: entries, cur: insertAt)),
    );

    if (event.quick) {
      _emitSignal(WorkoutToastSignal(t('{0} added', <Object?>[event.exId])), emit);
    }
  }

  /// Swaps an exercise in the active workout session.
  /// Ported from ../openGym/frontend/src/sheets.jsx:1005-1075 swapActiveWorkoutExercise.
  Future<void> _onExerciseSwapped(WorkoutExerciseSwapped event) async {
    final GymState s = _gymState.state;
    final Workout? active = s.active;
    if (active == null || active.entries == null) return;
    if (event.index < 0 || event.index >= active.entries!.length) return;

    final WorkoutEntry curEntry = active.entries![event.index];
    final String? rid = curEntry.rid;
    final Routine? routine =
        rid != null ? s.routines?.firstWhereOrNull((Routine r) => r.id == rid) : null;

    RoutineExercise cfg = event.cfg;
    if (routine == null) {
      cfg = _engine.history.freestyleConfig(s, cfg);
    }
    List<SetEntry> sets = _engine.history.buildSets(s, cfg);
    if (routine != null) {
      final Prescription p = _engine.progression.nextPrescription(s, cfg, routine);
      sets = _engine.progression.applyPrescription(sets, p);
    }
    sets = _engine.history.applyIntensifierPlan(sets, cfg);

    final WorkoutEntry replacement = WorkoutEntry(
      id: event.exId,
      rid: rid,
      sets: sets,
    ).withExtraFields(<String, Object?>{'target': cfg.toJson()});

    final Workout? swapped = swapActiveExercise(
      active,
      event.index,
      replacement,
      options: event.options,
      history: _engine.history,
    );

    if (swapped != null) {
      if (swapped.entries != null && swapped.entries!.length > active.entries!.length) {
        final int insertAt = swapped.cur ?? (event.index + 1);
        if (insertAt <= _progressHighWater.length) {
          _progressHighWater.insert(insertAt, 0);
        } else {
          _progressHighWater.add(0);
        }
      } else if (event.index < _progressHighWater.length) {
        _progressHighWater[event.index] = 0;
      }
      await _gymState.mutate((GymState st) => st.copyWith(active: swapped));
    }
  }

  /// Removes an exercise from the active workout session.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:496-515 removeActiveExercise.
  Future<void> _onExerciseRemoved(int idx) async {
    final Workout? active = _gymState.state.active;
    if (active == null || active.entries == null) return;
    if (idx < 0 || idx >= active.entries!.length) return;

    final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
    entries.removeAt(idx);
    final List<WorkoutEntry> cleaned = _engine.history.cleanupSgWorkoutEntries(entries);
    int nextCur = active.cur ?? 0;
    if (nextCur >= cleaned.length) {
      nextCur = cleaned.isEmpty ? 0 : cleaned.length - 1;
    }

    if (idx < _progressHighWater.length) {
      _progressHighWater.removeAt(idx);
    }

    await _gymState.mutate(
      (GymState s) => s.copyWith(active: active.copyWith(entries: cleaned, cur: nextCur)),
    );
  }

  /// Appends all exercises from a routine to the active session.
  /// Ported from ../openGym/frontend/src/sheets.jsx:1913-1946 AddRoutineToSession.add.
  Future<void> _onRoutineAddedToSession(
    String routineId,
    Emitter<WorkoutState> emit,
  ) async {
    final GymState s = _gymState.state;
    final Workout? active = s.active;
    if (active == null) return;

    final Routine? routine =
        s.routines?.firstWhereOrNull((Routine r) => r.id == routineId);
    if (routine == null) return;

    final List<RoutineExercise> exercises =
        routine.ex ?? const <RoutineExercise>[];
    final List<WorkoutEntry> newEntries = <WorkoutEntry>[];
    for (final RoutineExercise ex in exercises) {
      List<SetEntry> sets = _engine.history.buildSets(s, ex);
      final Prescription p = _engine.progression.nextPrescription(s, ex, routine);
      sets = _engine.progression.applyPrescription(sets, p);
      sets = _engine.history.applyIntensifierPlan(sets, ex);
      newEntries.add(
        WorkoutEntry(
          id: ex.id,
          rid: routine.id,
          sets: sets,
        ).withExtraFields(<String, Object?>{'target': ex.toJson()}),
      );
    }

    final List<WorkoutEntry> currentEntries =
        active.entries != null ? List<WorkoutEntry>.from(active.entries!) : <WorkoutEntry>[];
    currentEntries.addAll(newEntries);

    final List<String> currentRoutineIds =
        List<String>.from(active.routineIds ?? const <String>[]);
    final String? rId = routine.id;
    if (rId != null && !currentRoutineIds.contains(rId)) {
      currentRoutineIds.add(rId);
    }

    for (int i = 0; i < newEntries.length; i++) {
      _progressHighWater.add(0);
    }

    await _gymState.mutate(
      (GymState st) => st.copyWith(
        active: active.copyWith(entries: currentEntries, routineIds: currentRoutineIds),
      ),
    );

    final String rName = routine.name ?? routine.id ?? '';
    final String countMsg = t('{0} exercises', <Object?>[newEntries.length]);
    _emitSignal(WorkoutToastSignal(t('{0} added — {1}', <Object?>[rName, countMsg])), emit);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
