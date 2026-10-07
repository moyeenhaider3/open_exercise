// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/backup/auto_backup_sync.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/format/workout_controls.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/history_models.dart';
import '../../../core/js/models/phase3_models.dart';
import '../../../core/js/models/progression_models.dart';
import '../../../core/js/modules/backfill_js.dart';
import '../../../core/js/modules/finish_workout_js.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/progression_js.dart';
import '../../../core/js/modules/session_js.dart';
import '../../../core/js/modules/superset_flow_js.dart';
import '../../../core/js/modules/workout_model_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/set_entry.dart';
import '../../../core/models/workout.dart';
import '../../../core/sound/timer_sound.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../data/active_exercise_swap.dart';
import '../data/active_workout_order.dart';
import '../data/superset_flow.dart';
import 'workout_entry_view.dart';
import 'workout_event.dart';
import 'workout_state.dart';
import 'workout_timer_bloc.dart';
import 'workout_timer_event.dart';
import 'workout_timer_state.dart';

/// App-scoped BLoC managing workout lifecycle and session-level mutations.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Domain math, progression, and workout completion delegate exclusively to
/// QuickJS/JSC via [JsEngineService] (JS-04).
///
/// Phase 5 (05-07): rest and work countdown timers are driven by [WorkoutTimerBloc];
/// rest decisions delegate to [SupersetFlowJs]; sound cues use [TimerSound].
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
    required ExerciseCatalogue catalogue,
    required WorkoutTimerBloc timer,
    required TimerSound sound,
    required AutoBackupSync autoBackupSync,
  })  : _gymState = gymState,
        _engine = engine,
        _catalogue = catalogue,
        _timer = timer, // ignore: prefer_initializing_formals
        _sound = sound, // ignore: prefer_initializing_formals
        _autoBackupSync = autoBackupSync, // ignore: prefer_initializing_formals
        super(createState(gymState.state, engine, catalogue)) {
    on<WorkoutEvent>(_onEvent, transformer: _sequential<WorkoutEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(WorkoutGymStateChanged(s));
    });
    _timerSubscription = _timer.stream.listen((WorkoutTimerState ts) {
      // WorkoutTimerWorkDone is a one-shot signal detected by seq change.
      final WorkoutTimerSignal? sig = ts.signal;
      if (sig is WorkoutTimerWorkDone && ts.seq != _lastTimerSeq) {
        _lastTimerSeq = ts.seq;
        add(WorkoutTimedSetLogged(sig.entryIdx, sig.setIdx, sig.elapsedSec));
      }
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  final ExerciseCatalogue _catalogue;
  final WorkoutTimerBloc _timer;
  final TimerSound _sound;
  final AutoBackupSync _autoBackupSync;
  StreamSubscription<GymState>? _subscription;
  StreamSubscription<WorkoutTimerState>? _timerSubscription;

  List<int> _progressHighWater = <int>[];
  int _seq = 0;
  int _lastTimerSeq = 0;

  final Map<String, ({int hash, WorkoutEntryView view})> _entryViewCache =
      <String, ({int hash, WorkoutEntryView view})>{};

  /// High-water set index progress tracking for superset flow and progression (used by 03-10).
  List<int> get progressHighWater => List<int>.unmodifiable(_progressHighWater);

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  static WorkoutState createState(
    GymState s,
    JsEngineService engine,
    ExerciseCatalogue catalogue, [
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

    final List<WorkoutEntryView> entryViews = entries
        .map((WorkoutEntry entry) => WorkoutEntryView.build(
              entry: entry,
              s: s,
              engine: engine,
              catalogue: catalogue,
            ))
        .toList();

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
      entryViews: List<WorkoutEntryView>.unmodifiable(entryViews),
      signal: signal,
      seq: seq,
    );
  }

  WorkoutState _stateFromGym(
    GymState s, [
    WorkoutSignal? signal,
    int seq = 0,
  ]) {
    final Workout? active = s.active;
    if (active == null) {
      _entryViewCache.clear();
      return WorkoutNone(signal: signal, seq: seq);
    }
    final List<WorkoutEntry> entries = active.entries ?? const <WorkoutEntry>[];
    final List<List<int>> units = _engine.history.supersetUnits(entries);
    final int cur = entries.isEmpty ? 0 : (active.cur ?? 0).clamp(0, entries.length - 1);
    final List<int> currentUnit = entries.isEmpty ? const <int>[] : _engine.history.unitOf(units, cur);
    final int unitIdx = units.indexWhere((List<int> u) => u.contains(cur));
    final String view = active.workoutView ?? s.workoutView ?? 'cards';
    final int setsDone = _engine.history.setsDoneActive(active);
    final int setsTotal = _engine.history.setUnitsTotal(entries);
    final WorkoutControlsView wc = workoutControls(s);

    final List<WorkoutEntryView> entryViews = <WorkoutEntryView>[];
    for (int i = 0; i < entries.length; i++) {
      final WorkoutEntry entry = entries[i];
      final String cacheKey = '$i:${entry.id}';
      final int entryHash = Object.hash(
        entry,
        s.unit,
        s.effort,
        s.wc,
        s.barWeights?[entry.id],
        s.exNotes?[entry.id],
        s.exWeights?[entry.id]?.w,
        s.workouts?.length,
        s.customEx?.length,
      );

      final cached = _entryViewCache[cacheKey];
      if (cached != null && cached.hash == entryHash) {
        entryViews.add(cached.view);
      } else {
        final WorkoutEntryView view = WorkoutEntryView.build(
          entry: entry,
          s: s,
          engine: _engine,
          catalogue: _catalogue,
        );
        _entryViewCache[cacheKey] = (hash: entryHash, view: view);
        entryViews.add(view);
      }
    }

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
      entryViews: List<WorkoutEntryView>.unmodifiable(entryViews),
      signal: signal,
      seq: seq,
    );
  }

  void _emitSignal(WorkoutSignal sig, Emitter<WorkoutState> emit) {
    _seq++;
    emit(_stateFromGym(_gymState.state, sig, _seq));
  }

  Future<void> _onEvent(WorkoutEvent event, Emitter<WorkoutState> emit) async {
    switch (event) {
      case WorkoutTimedSetStarted():
        _onTimedSetStarted(event);
      case WorkoutTimedSetLogged():
        await _onTimedSetLogged(event, emit);
      case WorkoutGymStateChanged(:final GymState state):
        _onGymStateChanged(state, emit);
      case WorkoutStartRequested():
        await _onStartRequested(event, emit);
      case WorkoutBackfillStarted():
        await _onBackfillStarted(event, emit);
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
      case WorkoutSetFieldChanged():
        await _onSetFieldChanged(event);
      case WorkoutSetFieldBumped():
        await _onSetFieldBumped(event);
      case WorkoutSetAdded():
        await _onSetAdded(event);
      case WorkoutSetRemoved():
        await _onSetRemoved(event);
      case WorkoutWarmupAdded():
        await _onWarmupAdded(event);
      case WorkoutSetRemovedAt():
        await _onSetRemovedAt(event);
      case WorkoutDropAdded():
        await _onDropAdded(event);
      case WorkoutBurstAdded():
        await _onBurstAdded(event);
      case WorkoutDropFieldBumped():
        await _onDropFieldBumped(event);
      case WorkoutBurstFieldBumped():
        await _onBurstFieldBumped(event);
      case WorkoutDropRemoved():
        await _onDropRemoved(event);
      case WorkoutBurstRemoved():
        await _onBurstRemoved(event);
      case WorkoutDropFieldChanged():
        await _onDropFieldChanged(event);
      case WorkoutBurstFieldChanged():
        await _onBurstFieldChanged(event);
      case WorkoutSideFieldChanged():
        await _onSideFieldChanged(event);
      case WorkoutSetToggled():
        await _onSetToggled(event, emit);
      case WorkoutEffortPicked():
        await _onEffortPicked(event, emit);
      case WorkoutProgressionConfigured():
        await _onProgressionConfigured(event);
    }
  }

  void _onGymStateChanged(GymState state, Emitter<WorkoutState> emit) {
    emit(_stateFromGym(state, null, _seq));
  }

  /// Begins a workout session.
  /// Ported from ../openGym/frontend/src/sheets.jsx:1804-1832 beginWorkout and BwSheet.save (200-216).
  /// Phase 5 (05-07): stops rest timer; work timer is left running until exercise operations stop it.
  Future<void> _onStartRequested(
    WorkoutStartRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    _progressHighWater = <int>[];
    _stopRest();
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

      final (List<WorkoutEntry> entries, List<String> resolvedRoutineIds, String sessionName) =
          _buildSessionEntries(s, event.routineIds);

      final Workout active = Workout(
        id: uid(),
        d: today,
        start: now,
        routineIds: resolvedRoutineIds,
        name: sessionName,
        bw: loggedBw,
        cur: 0,
        entries: entries,
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

  /// Begins a backfilled workout session for a past day.
  /// Ported from ../openGym/frontend/src/sheets.jsx:1890-1907 beginBackfill.
  /// Phase 5 (05-07): stops rest timer; work is never started for backfill (_startRest is a no-op).
  Future<void> _onBackfillStarted(
    WorkoutBackfillStarted event,
    Emitter<WorkoutState> emit,
  ) async {
    _progressHighWater = <int>[];
    _stopRest();
    final int startEpoch = _engine.backfill.backfillStart(event.iso, event.time);
    final List<String> rids =
        event.routineId != null ? <String>[event.routineId!] : const <String>[];

    await _gymState.mutate((GymState s) {
      final (List<WorkoutEntry> entries, List<String> resolvedRoutineIds, String sessionName) =
          _buildSessionEntries(s, rids);

      final Workout active = Workout(
        id: uid(),
        d: event.iso,
        start: startEpoch,
        routineIds: resolvedRoutineIds,
        name: sessionName,
        bw: null,
        cur: 0,
        entries: entries,
      ).withExtraFields(<String, Object?>{
        'backfill': <String, Object?>{
          'durationMin': event.durationMin,
          'replaceId': event.replaceId,
        },
        'workoutView': s.workoutView ?? 'cards',
      });

      return s.copyWith(active: active);
    });

    _emitSignal(const WorkoutStartedSignal(), emit);
  }

  /// Helper to combine routine entries and derive session name.
  (List<WorkoutEntry>, List<String>, String) _buildSessionEntries(
    GymState s,
    List<String> routineIds,
  ) {
    final CombinedSession combined =
        _engine.sessionMerge.buildCombinedEntries(s, routineIds);
    final List<String> names = (combined.routines ?? const <Routine>[])
        .map((Routine r) => r.name ?? '')
        .where((String n) => n.isNotEmpty)
        .toList();
    final String sessionName = routineIds.isEmpty
        ? t('Freestyle')
        : (_engine.sessionMerge.deriveSessionName(names) ?? t('Freestyle'));
    return (
      combined.entries ?? const <WorkoutEntry>[],
      combined.routineIds ?? routineIds,
      sessionName,
    );
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
  /// Ported from ../openGym/frontend/src/sheets.jsx:2200-2228 doFinishWorkout
  /// and lines 2188-2227 (live and backfill finish branches).
  /// Phase 5 (05-07): stops rest timer and plays finish beeps (sheets.jsx:2225-2226).
  /// Note: autoBackupNow is deferred to Phase 8.
  Future<void> _onFinishConfirmed(Emitter<WorkoutState> emit) async {
    final GymState s = _gymState.state;
    if (s.active == null) return;
    _stopRest();
    final bool snd = s.sound == true;
    _sound.beep(snd, 880, 0.15);        // sheets.jsx:2225
    _sound.beep(snd, 1100, 0.15, 0.18); // sheets.jsx:2225
    _sound.beep(snd, 1320, 0.3, 0.36);  // sheets.jsx:2226
    final int now = DateTime.now().millisecondsSinceEpoch;
    final FinishResult result = _engine.finish.completeWorkout(s, now);
    _progressHighWater = <int>[];

    final bool isFirstWorkout = s.workouts == null || s.workouts!.isEmpty;
    await _gymState.mutate((GymState st) {
      if (result.past) {
        final List<Workout> nextWorkouts = _engine.backfill.completeBackfill(
          st.workouts ?? const <Workout>[],
          st.active!,
          result.workout,
        );
        return st.copyWith(
          workouts: nextWorkouts,
          active: null,
        );
      } else {
        final List<Workout> nextWorkouts = List<Workout>.from(st.workouts ?? const <Workout>[]);
        nextWorkouts.add(result.workout);
        return st.copyWith(
          workouts: nextWorkouts,
          exWeights: result.exWeights,
          active: null,
        );
      }
    });

    _emitSignal(WorkoutFinishedSignal(result, isFirstWorkout: isFirstWorkout), emit);

    // D-06(a): auto-backup after finishing a workout (openGym sheets.jsx:2224)
    unawaited(_autoBackupSync.autoBackupNow());
  }

  /// Discards the active workout without saving to history.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:982.
  /// Phase 5 (05-07): stops rest and work timers (Workout.jsx:982).
  Future<void> _onDiscarded() async {
    _progressHighWater = <int>[];
    _stopRest();
    _stopWork();
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
    // Workout.jsx:674 — return early when work timer is running.
    if (_workRunning) return;
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

    // Workout.jsx:685 — remap rest owner after unit move.
    _timer.add(WorkoutRestOwnerRemapped(moveResult.indices));

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

    // Workout.jsx:1087-1090 — shift rest owner when an exercise is inserted.
    _timer.add(WorkoutRestOwnerShifted(at: insertAt, delta: 1));

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
      // sheets.jsx:1041-1042 — stop work and rest before mutation.
      _stopWork();
      _stopRest();
      await _gymState.mutate((GymState st) => st.copyWith(active: swapped));
    }
  }

  /// Removes an exercise from the active workout session.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:496-515 removeActiveExercise.
  /// Phase 5 (05-07): tells WorkoutTimerBloc to stop work and stop/shift rest (lines 495-510).
  Future<void> _onExerciseRemoved(int idx) async {
    final Workout? active = _gymState.state.active;
    if (active == null || active.entries == null) return;
    if (idx < 0 || idx >= active.entries!.length) return;

    // Workout.jsx:495-510 — notify timer before mutating so indices are still valid.
    _timer.add(WorkoutRestExerciseRemoved(idx));

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

  /// Updates a single field on a set row, cascading weight if field is 'w'.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:629-637 setField.
  Future<void> _onSetFieldChanged(WorkoutSetFieldChanged event) async {
    const Set<String> allowedFields = <String>{'w', 'r', 'min', 'sec', 'speed', 'rir', 'rpe'};
    if (!allowedFields.contains(event.field)) return;

    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final Map<String, Object?> rowMap = sets[event.setIdx].toJson();
      if (event.value == null) {
        rowMap.remove(event.field);
      } else {
        rowMap[event.field] = event.value;
      }
      sets[event.setIdx] = SetEntry.fromJson(rowMap);

      List<SetEntry> nextSets = sets;
      if (event.field == 'w') {
        nextSets = _engine.history.cascadeWeight(sets, event.setIdx, event.value);
      }

      entries[event.entryIdx] = entry.copyWith(sets: nextSets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Steps a set field up (+1) or down (-1), snapping weight via ProgressionJs.stepWeight.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:174-180 bump, 286-294 sideBump.
  Future<void> _onSetFieldBumped(WorkoutSetFieldBumped event) async {
    const Set<String> allowedFields = <String>{'w', 'r', 'min', 'sec', 'speed', 'rir', 'rpe'};
    if (!allowedFields.contains(event.field)) return;

    final GymState state = _gymState.state;
    final Workout? active = state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;

    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;

    final SetEntry row = entry.sets![event.setIdx];

    if (event.side != null) {
      // sideBump (Workout.jsx:286-294)
      final SetEntry? sideRow = event.side == 'L' ? row.sides?.left : row.sides?.right;
      final num cur = (sideRow?.toJson()[event.field] as num?) ?? 0;
      if (event.field == 'w') {
        final num nextV = _engine.progression.stepWeight(cur, event.step, event.direction);
        await _gymState.mutate((GymState s) {
          final Workout? act = s.active;
          if (act == null || act.entries == null || event.entryIdx >= act.entries!.length) return s;
          final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
          final WorkoutEntry curEntry = entries[event.entryIdx];
          if (curEntry.sets == null || event.setIdx >= curEntry.sets!.length) return s;
          final List<SetEntry> sets = List<SetEntry>.from(curEntry.sets!);
          sets[event.setIdx] = _engine.workoutModel.setSideField(sets[event.setIdx], event.side!, event.field, nextV);
          entries[event.entryIdx] = curEntry.copyWith(sets: sets);
          return s.copyWith(active: act.copyWith(entries: entries));
        });
      } else if (event.field == 'rir' || event.field == 'rpe') {
        final String kind = _engine.history.effortOf(state);
        final num? rawCur = sideRow?.toJson()[event.field] as num?;
        final double? nextV = _engine.history.stepEffort(kind, rawCur, event.direction);
        await _gymState.mutate((GymState s) {
          final Workout? act = s.active;
          if (act == null || act.entries == null || event.entryIdx >= act.entries!.length) return s;
          final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
          final WorkoutEntry curEntry = entries[event.entryIdx];
          if (curEntry.sets == null || event.setIdx >= curEntry.sets!.length) return s;
          final List<SetEntry> sets = List<SetEntry>.from(curEntry.sets!);
          sets[event.setIdx] = _engine.workoutModel.setSideField(sets[event.setIdx], event.side!, event.field, nextV);
          entries[event.entryIdx] = curEntry.copyWith(sets: sets);
          return s.copyWith(active: act.copyWith(entries: entries));
        });
      } else {
        final num effectiveStep = event.field == 'r' ? 1 : event.step;
        // UI stepper rounding (Workout.jsx:293)
        final num raw = (((cur + event.direction * effectiveStep) * 100).round()) / 100;
        final num nextV = raw < 0 ? 0 : raw;
        await _gymState.mutate((GymState s) {
          final Workout? act = s.active;
          if (act == null || act.entries == null || event.entryIdx >= act.entries!.length) return s;
          final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
          final WorkoutEntry curEntry = entries[event.entryIdx];
          if (curEntry.sets == null || event.setIdx >= curEntry.sets!.length) return s;
          final List<SetEntry> sets = List<SetEntry>.from(curEntry.sets!);
          sets[event.setIdx] = _engine.workoutModel.setSideField(sets[event.setIdx], event.side!, event.field, nextV);
          entries[event.entryIdx] = curEntry.copyWith(sets: sets);
          return s.copyWith(active: act.copyWith(entries: entries));
        });
      }
    } else {
      // bump (Workout.jsx:174-180)
      final RoutineExercise cfg = entry.target ?? RoutineExercise(id: entry.id);
      final String mode = _engine.history.modeOf(cfg);
      final num? cur = row.toJson()[event.field] as num?;
      if (mode == 'reps' && event.field == 'w') {
        final num nextV = _engine.progression.stepWeight(cur, event.step, event.direction);
        await _onSetFieldChanged(WorkoutSetFieldChanged(event.entryIdx, event.setIdx, event.field, nextV));
      } else if (event.field == 'rir' || event.field == 'rpe') {
        final String kind = _engine.history.effortOf(state);
        final double? nextV = _engine.history.stepEffort(kind, cur, event.direction);
        await _onSetFieldChanged(WorkoutSetFieldChanged(event.entryIdx, event.setIdx, event.field, nextV));
      } else {
        // UI stepper rounding (Workout.jsx:179)
        final num raw = ((((cur ?? 0) + event.direction * event.step) * 100).round()) / 100;
        final num nextV = raw < 0 ? 0 : raw;
        await _onSetFieldChanged(WorkoutSetFieldChanged(event.entryIdx, event.setIdx, event.field, nextV));
      }
    }
  }

  /// Appends a new set row to an active workout exercise.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:639-654 addSet.
  Future<void> _onSetAdded(WorkoutSetAdded event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      final List<SetEntry> sets =
          entry.sets != null ? List<SetEntry>.from(entry.sets!) : <SetEntry>[];
      final SetEntry? l = sets.isNotEmpty ? sets.last : null;
      final RoutineExercise cfg = entry.target ?? RoutineExercise(id: entry.id);
      final String m = _engine.history.modeOf(cfg);

      if (m == 'cardio') {
        final num minVal = l?.min ?? cfg.min ?? 20;
        final num speedVal = l?.speed ?? cfg.speed ?? 8;
        sets.add(
          const SetEntry(done: false).withExtraFields(<String, Object?>{
            'min': minVal,
            'speed': speedVal,
          }),
        );
      } else if (m == 'time') {
        final num secVal = l?.sec ?? cfg.sec ?? 45;
        final num wVal = l?.w ?? cfg.weight ?? 0;
        sets.add(
          SetEntry(w: wVal, done: false).withExtraFields(<String, Object?>{
            'sec': secVal,
          }),
        );
      } else {
        final num wVal = l?.w ?? 0;
        final num rVal = l?.r ?? cfg.reps ?? 0;
        final SetEntry row = SetEntry(w: wVal, r: rVal, done: false);
        if (_engine.history.isPerSide(cfg)) {
          if (l != null && _engine.workoutModel.isSideSet(l)) {
            final num leftW = l.sides?.left?.w ?? 0;
            final num leftR = l.sides?.left?.r ?? 0;
            sets.add(_engine.workoutModel.makeSideSet(
              SetEntry(w: leftW, r: leftR * 2, done: false),
            ));
          } else {
            sets.add(_engine.workoutModel.makeSideSet(row));
          }
        } else {
          sets.add(row);
        }
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Removes the last set of an exercise if more than 1 set remains.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:655 removeSet.
  Future<void> _onSetRemoved(WorkoutSetRemoved event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || entry.sets!.length <= 1) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      sets.removeLast();
      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Inserts a warm-up row ramping toward the work weight.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:656-659 addWarmup.
  Future<void> _onWarmupAdded(WorkoutWarmupAdded event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      final List<SetEntry> sets = entry.sets ?? const <SetEntry>[];
      final RoutineExercise cfg = entry.target ?? RoutineExercise(id: entry.id);
      final String m = _engine.history.modeOf(cfg);
      final double step = _engine.progression.defaultIncrement(entry.id, s.unit);
      final List<SetEntry> updatedSets = _engine.history.insertWarmupRow(sets, m, cfg, step: step);

      entries[event.entryIdx] = entry.copyWith(sets: updatedSets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Removes a set row by index.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:660 removeSetAt.
  Future<void> _onSetRemovedAt(WorkoutSetRemovedAt event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> updatedSets = _engine.history.removeRowAt(entry.sets!, event.setIdx);
      entries[event.entryIdx] = entry.copyWith(sets: updatedSets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Appends a drop set to a set row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:87-97 addDropRow.
  Future<void> _onDropAdded(WorkoutDropAdded event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      num? pct;
      final Object? rawIntensifier = entry.target?.extra['intensifier'];
      if (rawIntensifier is Map && rawIntensifier['type'] == 'dropset') {
        pct = rawIntensifier['pct'] as num?;
      }

      if (_engine.workoutModel.isSideSet(row)) {
        sets[event.setIdx] = _engine.workoutModel.addSideDrop(row, pct: pct);
      } else {
        final List<DropEntry> drops = _engine.workoutModel.dropsOf(row);
        final num base = drops.isNotEmpty ? (drops.last.w ?? 0) : (row.w ?? 0);
        final double nextW = _engine.workoutModel.nextDropWeight(base, pct: pct);
        sets[event.setIdx] = _engine.workoutModel.addDrop(row, DropEntry(w: nextW, r: row.r));
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Appends a rest-pause cluster burst to a set row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:101-108 addBurstRow.
  Future<void> _onBurstAdded(WorkoutBurstAdded event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      num restSec = s.restPauseSec ?? 15;
      final Object? rawIntensifier = entry.target?.extra['intensifier'];
      if (rawIntensifier is Map && rawIntensifier['type'] == 'restpause') {
        if (rawIntensifier['restSec'] is num) {
          restSec = rawIntensifier['restSec'] as num;
        }
      }

      if (_engine.workoutModel.isSideSet(row)) {
        sets[event.setIdx] = _engine.workoutModel.addSideCluster(row, restSec: restSec);
      } else {
        final List<ClusterEntry> clusters = _engine.workoutModel.clustersOf(row);
        final num base = clusters.isNotEmpty ? (clusters.last.r ?? 0) : (row.r ?? 0);
        final int added = _engine.workoutModel.nextBurstReps(base);
        final SetEntry updated = _engine.workoutModel.addCluster(
          row,
          ClusterEntry(r: added, restSec: restSec),
        );
        sets[event.setIdx] = updated.copyWith(r: (row.r ?? 0) + added);
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Steps a drop-set field value up or down.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:346-347, 361-367 miniStepper.
  Future<void> _onDropFieldBumped(WorkoutDropFieldBumped event) async {
    final GymState state = _gymState.state;
    final Workout? active = state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;

    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;

    final SetEntry row = entry.sets![event.setIdx];
    final List<DropEntry> drops = event.side != null
        ? _engine.workoutModel.dropsOf(event.side == 'L' ? row.sides?.left : row.sides?.right)
        : _engine.workoutModel.dropsOf(row);

    if (event.dropIdx < 0 || event.dropIdx >= drops.length) return;

    final DropEntry drop = drops[event.dropIdx];
    final num cur = (event.field == 'w' ? drop.w : drop.r) ?? 0;

    final num nextV;
    if (event.field == 'w') {
      nextV = _engine.progression.stepWeight(cur, event.step, event.direction);
    } else {
      // UI stepper rounding (Workout.jsx:361-367)
      final num raw = (((cur + event.direction * event.step) * 100).round()) / 100;
      nextV = raw < 0 ? 0 : raw;
    }

    await _onDropFieldChanged(WorkoutDropFieldChanged(
      event.entryIdx,
      event.setIdx,
      event.dropIdx,
      event.field,
      nextV,
      side: event.side,
    ));
  }

  /// Steps a rest-pause burst reps count up or down.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:351, 361-367 miniStepper.
  Future<void> _onBurstFieldBumped(WorkoutBurstFieldBumped event) async {
    final GymState state = _gymState.state;
    final Workout? active = state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;

    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;

    final SetEntry row = entry.sets![event.setIdx];
    final List<ClusterEntry> clusters = event.side != null
        ? _engine.workoutModel.clustersOf(event.side == 'L' ? row.sides?.left : row.sides?.right)
        : _engine.workoutModel.clustersOf(row);

    if (event.clusterIdx < 0 || event.clusterIdx >= clusters.length) return;

    final num cur = clusters[event.clusterIdx].r ?? 0;
    // UI stepper rounding (Workout.jsx:361-367)
    final num raw = (((cur + event.direction) * 100).round()) / 100;
    final num nextV = raw < 0 ? 0 : raw;

    await _onBurstFieldChanged(WorkoutBurstFieldChanged(
      event.entryIdx,
      event.setIdx,
      event.clusterIdx,
      nextV,
      side: event.side,
    ));
  }

  /// Removes a drop set from a set row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:113 removeDrop.
  Future<void> _onDropRemoved(WorkoutDropRemoved event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      sets[event.setIdx] = _engine.workoutModel.isSideSet(row)
          ? _engine.workoutModel.removeSideDropAt(row, event.dropIdx)
          : _engine.workoutModel.removeDropAt(row, event.dropIdx);

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Removes a rest-pause cluster burst from a set row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:114-118 removeCluster.
  Future<void> _onBurstRemoved(WorkoutBurstRemoved event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      if (_engine.workoutModel.isSideSet(row)) {
        sets[event.setIdx] = _engine.workoutModel.removeSideClusterAt(row, event.clusterIdx);
      } else {
        final List<ClusterEntry> clusters = _engine.workoutModel.clustersOf(row);
        final num removed = (event.clusterIdx < clusters.length ? clusters[event.clusterIdx].r : null) ?? 0;
        final SetEntry nextRow = _engine.workoutModel.removeClusterAt(row, event.clusterIdx);
        final num diff = (row.r ?? 0) - removed;
        sets[event.setIdx] = nextRow.copyWith(r: diff < 0 ? 0 : diff);
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Changes a field value on a drop set row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:119 setDropField.
  Future<void> _onDropFieldChanged(WorkoutDropFieldChanged event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      if (event.side != null) {
        sets[event.setIdx] = _engine.workoutModel.setSideDropAt(
          row,
          event.side!,
          event.dropIdx,
          <String, Object?>{event.field: event.value},
        );
      } else {
        sets[event.setIdx] = _engine.workoutModel.setDropAt(
          row,
          event.dropIdx,
          <String, Object?>{event.field: event.value},
        );
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Changes reps on a rest-pause cluster burst row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:121-125 setClusterField.
  Future<void> _onBurstFieldChanged(WorkoutBurstFieldChanged event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      final SetEntry row = sets[event.setIdx];

      if (event.side != null) {
        sets[event.setIdx] = _engine.workoutModel.setSideClusterAt(
          row,
          event.side!,
          event.clusterIdx,
          event.value,
        );
      } else {
        final List<ClusterEntry> clusters = _engine.workoutModel.clustersOf(row);
        final num oldR = (event.clusterIdx < clusters.length ? clusters[event.clusterIdx].r : null) ?? 0;
        final num delta = (event.value ?? 0) - oldR;
        final SetEntry nextRow = _engine.workoutModel.setClusterAt(
          row,
          event.clusterIdx,
          <String, Object?>{'r': event.value},
        );
        final num totalR = (row.r ?? 0) + delta;
        sets[event.setIdx] = nextRow.copyWith(r: totalR < 0 ? 0 : totalR);
      }

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Updates a field on a unilateral side set.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:110 setSide.
  Future<void> _onSideFieldChanged(WorkoutSideFieldChanged event) async {
    await _gymState.mutate((GymState s) {
      final Workout? active = s.active;
      if (active == null || active.entries == null) return s;
      if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(active.entries!);
      final WorkoutEntry entry = entries[event.entryIdx];
      if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(entry.sets!);
      sets[event.setIdx] = _engine.workoutModel.setSideField(
        sets[event.setIdx],
        event.side,
        event.field,
        event.value,
      );

      entries[event.entryIdx] = entry.copyWith(sets: sets);
      return s.copyWith(active: active.copyWith(entries: entries));
    });
  }

  /// Toggles the completion state of a set or side row.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:863-945 toggle.
  Future<void> _onSetToggled(WorkoutSetToggled event, Emitter<WorkoutState> emit) async {
    final GymState state = _gymState.state;
    final Workout? active = state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;

    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;

    final RoutineExercise cfg = entry.target ?? RoutineExercise(id: entry.id);
    final String m = _engine.history.modeOf(cfg);
    final bool cardioEntry = m == 'cardio';

    bool exJustDone = false;
    bool workoutDone = false;
    bool checked = false;

    final List<WorkoutEntry> currentEntries = active.entries!;
    final List<List<int>> units = _engine.history.supersetUnits(currentEntries);

    await _gymState.mutate((GymState s) {
      final Workout? act = s.active;
      if (act == null || act.entries == null) return s;
      if (event.entryIdx >= act.entries!.length) return s;

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
      final WorkoutEntry e = entries[event.entryIdx];
      if (e.sets == null || event.setIdx >= e.sets!.length) return s;

      final List<SetEntry> sets = List<SetEntry>.from(e.sets!);
      if (event.side != null) {
        sets[event.setIdx] = _engine.workoutModel.toggleSide(sets[event.setIdx], event.side!);
      } else {
        final bool prevDone = sets[event.setIdx].done == true;
        sets[event.setIdx] = sets[event.setIdx].copyWith(done: !prevDone);
      }
      checked = sets[event.setIdx].done == true;

      WorkoutEntry updatedEntry = e.copyWith(sets: sets);

      if (checked) {
        // Phase 5 (05-07): beep + vibrate on check (Workout.jsx:880).
        final bool snd = state.sound == true;
        _sound.beep(snd, 1040, 0.12);
        _sound.vibrate(30);
        final List<int> ownUnit = _engine.history.unitOf(units, event.entryIdx);
        final bool unitDone = ownUnit.every((int ui) {
          final WorkoutEntry unitEntry = ui == event.entryIdx ? updatedEntry : entries[ui];
          return unitEntry.sets != null && unitEntry.sets!.every((SetEntry x) => x.done == true);
        });

        if (unitDone) {
          final List<List<int>> allUnits = _engine.history.supersetUnits(entries);
          final List<int>? nextUnit = nextUnfinishedUnit(entries, allUnits, event.entryIdx);
          workoutDone = nextUnit == null;
        }

        if (sets.every((SetEntry x) => x.done == true)) {
          exJustDone = true;
          final double topW = _engine.history.bestWeightForEntry(updatedEntry);
          updatedEntry = updatedEntry.copyWith(topW: topW > 0 ? topW : null);
        }
      }

      entries[event.entryIdx] = updatedEntry;
      return s.copyWith(active: act.copyWith(entries: entries));
    });

    if (workoutDone) {
      _emitSignal(const WorkoutAllDoneSignal(), emit);
    } else if (exJustDone && cardioEntry) {
      _emitSignal(WorkoutToastSignal(t('Cardio logged')), emit);
    } else if (exJustDone && m == 'time') {
      _emitSignal(WorkoutToastSignal(t('Hold logged')), emit);
    }

    final Workout? fresh = _gymState.state.active;
    if (fresh != null && checked && fresh.entries != null && event.entryIdx < fresh.entries!.length) {
      while (_progressHighWater.length <= event.entryIdx) {
        _progressHighWater.add(0);
      }
      final ({int highWater, bool isNew}) progress = setProgressHighWater(
        fresh.entries![event.entryIdx],
        _progressHighWater[event.entryIdx],
      );
      _progressHighWater[event.entryIdx] = progress.highWater;

      final List<List<int>> freshUnits = _engine.history.supersetUnits(fresh.entries!);
      final List<int>? freshUnit = freshUnits.firstWhereOrNull((List<int> u) => u.contains(event.entryIdx));
      final bool freshUnitDone = freshUnit != null &&
          freshUnit.every((int ui) {
            if (ui >= fresh.entries!.length) return false;
            final WorkoutEntry ue = fresh.entries![ui];
            return ue.sets != null && ue.sets!.every((SetEntry x) => x.done == true);
          });
      final List<int>? nextUnit = freshUnitDone
          ? nextUnfinishedUnit(fresh.entries!, freshUnits, event.entryIdx)
          : null;
      final bool freshWorkoutDone = freshUnitDone && nextUnit == null;
      // restBeforeWarmup: true when the next unit has any unfinished warm-up set.
      final bool restBeforeWarmup = nextUnit?.any((int ui) {
            if (ui >= fresh.entries!.length) return false;
            final WorkoutEntry ue = fresh.entries![ui];
            return ue.sets?.any(
                  (SetEntry s) => _engine.workoutModel.isWarmupRow(s) && s.done != true,
                ) ??
                false;
          }) ??
          false;

      final WorkoutEntry freshEntry = fresh.entries![event.entryIdx];
      final int defaultRest = _gymState.state.restSec?.toInt() ?? 90;
      final int restSec = _engine.supersetFlow.restSecFor(
        fresh.entries!,
        freshUnit ?? <int>[event.entryIdx],
        defaultRest,
      );
      final int restAfter = _engine.supersetFlow.warmupRestSecFor(
        freshEntry,
        event.setIdx,
        restSec,
      );

      // Phase 5 (05-07): openGym toggle rest logic (Workout.jsx:900-945).
      if (!progress.isNew) {
        // Recheck: restOnRecheck decides whether to (re)start rest.
        if (!restBeforeWarmup &&
            _engine.supersetFlow.restOnRecheck(
              timerRunning: _restRunning,
              unitDone: freshUnitDone,
              lastUnit: freshWorkoutDone,
            )) {
          _startRest(restAfter, event.entryIdx);
        }
        return;
      }

      if (freshUnitDone) {
        // Finished the whole unit — stop rest (superset branch will re-start if needed).
        _stopRest();
      }

      if (freshUnit == null || freshUnit.length <= 1) {
        // Singleton exercise.
        if (!restBeforeWarmup &&
            _engine.supersetFlow.restAfterSet(
              unitDone: freshUnitDone,
              lastUnit: freshWorkoutDone,
            )) {
          _startRest(restAfter, event.entryIdx);
        }
        return;
      }

      // Superset path.
      final SupersetFlowStep? step = supersetFlowStep(fresh.entries!, freshUnit, event.entryIdx);
      if (step == null) return;
      if (step.unitDone) {
        if (nextUnit != null && nextUnit.isNotEmpty && !restBeforeWarmup) {
          _startRest(restAfter, event.entryIdx);
        }
      } else {
        if (step.nextIdx != null) {
          await _gymState.mutate((GymState s) {
            if (s.active == null) return s;
            return s.copyWith(active: s.active!.copyWith(cur: step.nextIdx));
          });
        }
        if (step.roundDone) {
          _startRest(restAfter, event.entryIdx);
        }
      }
    }
  }

  /// Starts a work/hold timer for a timed set.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:848-861 startTimed.
  void _onTimedSetStarted(WorkoutTimedSetStarted event) {
    final Workout? active = _gymState.state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;
    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;
    final SetEntry set = entry.sets![event.setIdx];
    // Workout.jsx:858 `sec || 45`
    final Object? secVal = set.toJson()['sec'];
    final num rawSec = secVal is num && secVal > 0 ? secVal : 45;
    final ExerciseDef def = _catalogue.lookup(_gymState.state, entry.id ?? '');
    final String label = _catalogue.exerciseNameFor(def);
    _timer.add(WorkoutWorkStarted(
      sec: rawSec,
      label: label,
      entryIdx: event.entryIdx,
      setIdx: event.setIdx,
    ));
  }

  /// Logs elapsed seconds for a timed set, then runs the normal toggle path.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:848-861 startTimed onDone callback.
  Future<void> _onTimedSetLogged(
    WorkoutTimedSetLogged event,
    Emitter<WorkoutState> emit,
  ) async {
    final Workout? active = _gymState.state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;
    final WorkoutEntry entry = active.entries![event.entryIdx];
    if (entry.sets == null || event.setIdx < 0 || event.setIdx >= entry.sets!.length) return;

    // Mutate elapsed seconds onto the set row.
    await _gymState.mutate((GymState s) {
      final Workout? act = s.active;
      if (act == null || act.entries == null) return s;
      if (event.entryIdx >= act.entries!.length) return s;
      final WorkoutEntry e = act.entries![event.entryIdx];
      if (e.sets == null || event.setIdx >= e.sets!.length) return s;
      final List<SetEntry> sets = List<SetEntry>.from(e.sets!);
      final Map<String, Object?> map = sets[event.setIdx].toJson();
      map['sec'] = event.elapsedSec;
      sets[event.setIdx] = SetEntry.fromJson(map);
      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
      entries[event.entryIdx] = e.copyWith(sets: sets);
      return s.copyWith(active: act.copyWith(entries: entries));
    });

    // If the set is not yet done, run the normal toggle so rest/superset/finish apply.
    final Workout? fresh = _gymState.state.active;
    if (fresh != null && fresh.entries != null &&
        event.entryIdx < fresh.entries!.length) {
      final WorkoutEntry freshEntry = fresh.entries![event.entryIdx];
      if (freshEntry.sets != null &&
          event.setIdx < freshEntry.sets!.length &&
          freshEntry.sets![event.setIdx].done != true) {
        await _onSetToggled(WorkoutSetToggled(event.entryIdx, event.setIdx), emit);
      }
    }
  }

  /// Sets effort rating (RIR/RPE), concluding the set if value is non-null and set is not yet done.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:253-285 effortCell, 305-325 sideEffortCell.
  Future<void> _onEffortPicked(WorkoutEffortPicked event, Emitter<WorkoutState> emit) async {
    final GymState state = _gymState.state;
    final Workout? active = state.active;
    if (active == null || active.entries == null) return;
    if (event.entryIdx < 0 || event.entryIdx >= active.entries!.length) return;

    final String kind = _engine.history.effortOf(state);
    final EffortScale? eff = _engine.history.effort[kind];
    final String field = eff?.f ?? 'rir';

    if (event.side != null) {
      await _onSideFieldChanged(
        WorkoutSideFieldChanged(event.entryIdx, event.setIdx, event.side!, field, event.value),
      );
      if (event.value != null) {
        final Workout? fresh = _gymState.state.active;
        final SetEntry? freshRow =
            fresh?.entries?[event.entryIdx].sets?[event.setIdx];
        final bool sideDone =
            (event.side == 'L' ? freshRow?.sides?.left : freshRow?.sides?.right)?.done == true;
        if (!sideDone) {
          await _onSetToggled(WorkoutSetToggled(event.entryIdx, event.setIdx, side: event.side), emit);
        }
      }
    } else {
      await _onSetFieldChanged(
        WorkoutSetFieldChanged(event.entryIdx, event.setIdx, field, event.value),
      );
      if (event.value != null) {
        final Workout? fresh = _gymState.state.active;
        final SetEntry? freshRow =
            fresh?.entries?[event.entryIdx].sets?[event.setIdx];
        if (freshRow?.done != true) {
          await _onSetToggled(WorkoutSetToggled(event.entryIdx, event.setIdx), emit);
        }
      }
    }
  }

  /// Reconfigures progression settings and rebuilds sets for an active exercise.
  /// Ported from ../openGym/frontend/src/views/Workout.jsx:771-817 openProgressionSettings.
  Future<void> _onProgressionConfigured(WorkoutProgressionConfigured event) async {
    final GymState current = _gymState.state;
    final Workout? active = current.active;
    if (active == null ||
        active.id != event.activeId ||
        active.entries == null ||
        active.entries!.length != event.entryCount ||
        event.entryIdx < 0 ||
        event.entryIdx >= active.entries!.length ||
        active.entries![event.entryIdx].id != event.entryId) {
      return;
    }

    await _gymState.mutate((GymState s) {
      final Workout? act = s.active;
      if (act == null || act.id != event.activeId || act.entries == null) return s;
      if (event.entryIdx >= act.entries!.length) return s;
      final WorkoutEntry activeEntry = act.entries![event.entryIdx];
      if (activeEntry.id != event.entryId) return s;

      final RoutineExercise full = event.cfg.copyWith(id: activeEntry.id);
      final Routine? activeRoutine =
          s.routines?.firstWhereOrNull((Routine r) => r.id == activeEntry.rid);
      final String mode = _engine.history.modeOf(full);
      final double step = mode == 'reps'
          ? _engine.progression.weightIncrement(full, s.unit)
          : _engine.progression.defaultIncrement(activeEntry.id, s.unit);

      final List<SetEntry> currentSets = activeEntry.sets ?? const <SetEntry>[];
      RoutineExercise resolvedFull = full;
      if (!((resolvedFull.sets ?? 0) > 0)) {
        final int workCount =
            currentSets.where((SetEntry x) => !_engine.workoutModel.isWarmupRow(x)).length;
        resolvedFull = resolvedFull.copyWith(sets: workCount > 0 ? workCount : 1);
      }

      final Prescription plan =
          _engine.progression.nextPrescription(s, resolvedFull, activeRoutine);
      final List<SetEntry> built = _engine.history.buildSets(
        s,
        resolvedFull,
        options: BuildSetsOptions(step: step, useTarget: plan.kind == 'off'),
      );
      final List<SetEntry> prescribed =
          _engine.progression.applyPrescription(built, plan, step: step);
      final List<SetEntry> fresh =
          _engine.history.applyIntensifierPlan(prescribed, resolvedFull);

      final List<SetEntry> doneWarm = currentSets
          .where((SetEntry x) => x.done == true && _engine.workoutModel.isWarmupRow(x))
          .toList();
      final List<SetEntry> doneWork = currentSets
          .where((SetEntry x) => x.done == true && !_engine.workoutModel.isWarmupRow(x))
          .toList();
      final List<SetEntry> freshWarm = fresh.where(_engine.workoutModel.isWarmupRow).toList();
      final List<SetEntry> freshWork =
          fresh.where((SetEntry x) => !_engine.workoutModel.isWarmupRow(x)).toList();

      final List<SetEntry> mergedSets = <SetEntry>[
        ...doneWarm,
        ...freshWarm.skip(doneWarm.length),
        ...doneWork,
        ...freshWork.skip(doneWork.length),
      ];

      final WorkoutEntry updatedEntry = activeEntry.copyWith(
        sets: mergedSets,
      ).withExtraFields(<String, Object?>{
        'target': event.cfg.toJson(),
        'plan': plan.toJson(),
      });

      final List<WorkoutEntry> entries = List<WorkoutEntry>.from(act.entries!);
      entries[event.entryIdx] = updatedEntry;
      return s.copyWith(active: act.copyWith(entries: entries));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _timerSubscription?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Timer helpers — mirror openGym Workout.jsx startRest/stopRest/stopWork
  // ---------------------------------------------------------------------------

  /// Ports Workout.jsx startRest: no-op during backfill (line 525).
  void _startRest(int sec, int idx) {
    final Workout? active = _gymState.state.active;
    if (active?.extra['backfill'] != null) return;
    _timer.add(WorkoutRestStarted(sec: sec, forIdx: idx));
  }

  void _stopRest() => _timer.add(const WorkoutRestStopped());

  void _stopWork() => _timer.add(const WorkoutWorkStopped());

  bool get _restRunning => _timer.state is WorkoutRestRunning;

  bool get _workRunning => _timer.state is WorkoutWorkRunning;
}
