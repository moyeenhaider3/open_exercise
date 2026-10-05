// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of the timer + work slice of
/// ../openGym/frontend/src/store/useUI.js (lines 90-203).
///
/// Timing glue, not domain math (05-RESEARCH A3): rest/work countdowns,
/// sound cues, vibration, theme flash and background-rest notification
/// are UI concerns placed in the Dart layer, exactly as openGym keeps
/// them in useUI.js rather than in a shared lib/.
library;

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/sound/timer_sound.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'workout_timer_event.dart';
import 'workout_timer_state.dart';

/// App-scoped BLoC reproducing useUI.js rest/work timing, cues and seenLive rule.
///
/// Single event handler with [_sequential] transformer (same convention as [WorkoutBloc]).
/// Sound flag is read at tick time from [GymStateCubit.state.sound].
/// timerFlash flag is read from [GymStateCubit.state.timerFlash].
class WorkoutTimerBloc extends Bloc<WorkoutTimerEvent, WorkoutTimerState> {
  WorkoutTimerBloc({
    required GymStateCubit gymState,
    required NotificationService notifications,
    required TimerSound sound,
  })  : _gymState = gymState, // ignore: prefer_initializing_formals
        _notifications = notifications, // ignore: prefer_initializing_formals
        _sound = sound, // ignore: prefer_initializing_formals
        super(const WorkoutTimerIdle()) {
    on<WorkoutTimerEvent>(_onEvent, transformer: _sequential<WorkoutTimerEvent>());
  }

  final GymStateCubit _gymState;
  final NotificationService _notifications;
  final TimerSound _sound;

  Timer? _ticker;

  /// Mirrors useUI.js pageHiddenAt: null while visible, ms timestamp when hidden.
  int? _hiddenAt;

  /// Whether the app is currently visible (foreground).
  bool _visible = true;

  /// Internal flash ID counter.
  int _flashCounter = 0;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  // ---------------------------------------------------------------------------
  // Event dispatcher
  // ---------------------------------------------------------------------------

  Future<void> _onEvent(
    WorkoutTimerEvent event,
    Emitter<WorkoutTimerState> emit,
  ) async {
    switch (event) {
      case WorkoutRestStarted(:final int sec, :final int? forIdx):
        _startRest(sec, forIdx, emit);
      case WorkoutRestAdded(:final int sec):
        _addRest(sec, emit);
      case WorkoutRestOwnerShifted(:final int at, :final int delta):
        _shiftRestOwner(at, delta, emit);
      case WorkoutRestOwnerRemapped(:final List<int> indices):
        _remapRestOwner(indices, emit);
      case WorkoutRestExerciseRemoved(:final int idx):
        _onExerciseRemoved(idx, emit);
      case WorkoutRestStopped():
        _stopRest(emit);
      case WorkoutWorkStarted(
          :final num sec,
          :final String label,
          :final int entryIdx,
          :final int setIdx
        ):
        _startWork(sec, label, entryIdx, setIdx, emit);
      case WorkoutWorkFinishedEarly():
        _finishWorkEarly(emit);
      case WorkoutWorkStopped():
        _stopWork(emit);
      case WorkoutTimerTicked():
        _tick(emit);
      case WorkoutTimerAppHidden():
        _onAppHidden(emit);
      case WorkoutTimerAppShown():
        _onAppShown(emit);
    }
  }

  // ---------------------------------------------------------------------------
  // Rest timer — ports useUI.js startRest / addRest / shiftRestOwner / stopRest
  // ---------------------------------------------------------------------------

  /// useUI.js startRest(sec, forIdx) lines 107-113.
  void _startRest(int sec, int? forIdx, Emitter<WorkoutTimerState> emit) {
    _stopRest(emit);
    if (sec <= 0) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int endsAtMs = now + sec * 1000;
    emit(WorkoutRestRunning(
      left: sec,
      total: sec,
      endsAtMs: endsAtMs,
      forIdx: forIdx,
      flashId: state.flashId,
      seq: state.seq,
    ));
    _startTicker();
  }

  /// useUI.js addRest(sec) lines 143-151.
  void _addRest(int sec, Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is! WorkoutRestRunning) return;
    final int newLeft = s.left + sec;
    if (newLeft <= 0) {
      _stopRest(emit);
      return;
    }
    emit(s.copyWith(
      left: newLeft,
      total: s.total + sec,
      endsAtMs: s.endsAtMs + sec * 1000,
    ));
  }

  /// useUI.js shiftRestOwner(at, delta) lines 153-157.
  void _shiftRestOwner(int at, int delta, Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is! WorkoutRestRunning) return;
    final int? idx = s.forIdx;
    if (idx != null && idx >= at) {
      emit(s.copyWith(forIdx: idx + delta));
    }
  }

  /// Workout.jsx moveUnitAt remapping lines 671-686.
  void _remapRestOwner(List<int> indices, Emitter<WorkoutTimerState> emit) {
    _stopWork(emit);
    final WorkoutTimerState s = state;
    if (s is! WorkoutRestRunning) return;
    final int? idx = s.forIdx;
    if (idx == null) return;
    final int newIdx = indices.indexOf(idx);
    if (newIdx >= 0) {
      emit(s.copyWith(forIdx: newIdx));
    }
  }

  /// Workout.jsx removeActiveExercise lines 495-510.
  void _onExerciseRemoved(int idx, Emitter<WorkoutTimerState> emit) {
    _stopWork(emit);
    final WorkoutTimerState s = state;
    if (s is! WorkoutRestRunning) return;
    if (s.forIdx == idx) {
      _stopRest(emit);
    } else {
      _shiftRestOwner(idx + 1, -1, emit);
    }
  }

  /// useUI.js stopRest() lines 159-165.
  /// Cancels the notification whenever a rest existed (useUI.js:143).
  void _stopRest(Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is WorkoutRestRunning) {
      _cancelTicker();
      _notifications.cancelRestOver();
      emit(WorkoutTimerIdle(flashId: s.flashId, seq: s.seq));
    }
  }

  // ---------------------------------------------------------------------------
  // Work timer — ports useUI.js startWork / finishWorkEarly / stopWork
  // ---------------------------------------------------------------------------

  /// useUI.js startWork(sec, label, onDone) lines 167-185.
  void _startWork(
    num sec,
    String label,
    int entryIdx,
    int setIdx,
    Emitter<WorkoutTimerState> emit,
  ) {
    _stopWork(emit);
    _stopRest(emit);
    final int total = sec.round() < 1 ? 1 : sec.round();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int endsAtMs = now + total * 1000;
    emit(WorkoutWorkRunning(
      left: total,
      total: total,
      endsAtMs: endsAtMs,
      label: label,
      entryIdx: entryIdx,
      setIdx: setIdx,
      flashId: state.flashId,
      seq: state.seq,
    ));
    _startTicker();
  }

  /// useUI.js finishWorkEarly() lines 187-192.
  void _finishWorkEarly(Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is! WorkoutWorkRunning) return;
    _cancelTicker();
    final int elapsed = s.total - s.left;
    final int elapsedSec = elapsed < 1 ? 1 : elapsed;
    _sound.vibrate(30); // useUI.js:190 vibrate(30)
    _flashCounter++;
    final int nextFlash = _flash();
    final int nextSeq = s.seq + 1;
    emit(WorkoutTimerIdle(
      flashId: nextFlash,
      seq: nextSeq,
      signal: WorkoutTimerWorkDone(
        entryIdx: s.entryIdx,
        setIdx: s.setIdx,
        elapsedSec: elapsedSec,
      ),
    ));
  }

  /// useUI.js stopWork() lines 194-198.
  void _stopWork(Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is WorkoutWorkRunning) {
      _cancelTicker();
      emit(WorkoutTimerIdle(flashId: s.flashId, seq: s.seq));
    }
  }

  // ---------------------------------------------------------------------------
  // Tick — ports useUI.js timerTick lines 118-142
  // ---------------------------------------------------------------------------

  void _tick(Emitter<WorkoutTimerState> emit) {
    final WorkoutTimerState s = state;
    if (s is WorkoutRestRunning) {
      _tickRest(s, emit);
    } else if (s is WorkoutWorkRunning) {
      _tickWork(s, emit);
    }
  }

  void _tickRest(WorkoutRestRunning s, Emitter<WorkoutTimerState> emit) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    // seenLive: app is visible AND hiddenAt is null (not the first tick after return)
    final bool seenLive = _visible && _hiddenAt == null;

    // Clear hiddenAt if visible (openGym: hiddenAt is cleared after the first tick on return)
    if (_visible && _hiddenAt != null) {
      _hiddenAt = null;
    }

    final int rawLeft = ((s.endsAtMs - now) / 1000).round();
    final int left = rawLeft < 0 ? 0 : rawLeft;

    if (left == s.left) return; // no change yet

    if (left <= 0) {
      // Rest complete
      _cancelTicker();
      final bool snd = _gymState.state.sound == true;
      if (seenLive) {
        // useUI.js:134-138
        _sound.beep(snd, 880, 0.15);
        _sound.beep(snd, 880, 0.15, 0.25);
        _sound.beep(snd, 1320, 0.4, 0.5);
        _sound.vibrate(<int>[200, 100, 200]);
        _flash();
      }
      // Toast is shown by WorkoutTimerHost via BlocListener on signal; always emitted.
      _notifications.cancelRestOver();
      final int nextSeq = s.seq + 1;
      emit(WorkoutTimerIdle(
        flashId: state.flashId,
        seq: nextSeq,
        signal: const WorkoutTimerRestOver(),
      ));
      return;
    }

    if (left <= 3) {
      // useUI.js:141 beep tick
      final bool snd = _gymState.state.sound == true;
      _sound.beep(snd, 660, 0.1);
    }

    emit(s.copyWith(left: left));
  }

  void _tickWork(WorkoutWorkRunning s, Emitter<WorkoutTimerState> emit) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    final bool seenLive = _visible && _hiddenAt == null;
    if (_visible && _hiddenAt != null) {
      _hiddenAt = null;
    }

    final int rawLeft = ((s.endsAtMs - now) / 1000).round();
    final int left = rawLeft < 0 ? 0 : rawLeft;

    if (left == s.left) return;

    if (left <= 0) {
      _cancelTicker();
      final bool snd = _gymState.state.sound == true;
      if (seenLive) {
        // same cues as rest: useUI.js:134-138 (startWork reuses same tick logic)
        _sound.beep(snd, 880, 0.15);
        _sound.beep(snd, 880, 0.15, 0.25);
        _sound.beep(snd, 1320, 0.4, 0.5);
        _sound.vibrate(<int>[200, 100, 200]);
        _flash();
      }
      final int nextSeq = s.seq + 1;
      emit(WorkoutTimerIdle(
        flashId: state.flashId,
        seq: nextSeq,
        signal: WorkoutTimerWorkDone(
          entryIdx: s.entryIdx,
          setIdx: s.setIdx,
          elapsedSec: s.total,
        ),
      ));
      return;
    }

    emit(s.copyWith(left: left));
  }

  // ---------------------------------------------------------------------------
  // App lifecycle — ports useUI.js visibilitychange lines 96-106
  // ---------------------------------------------------------------------------

  void _onAppHidden(Emitter<WorkoutTimerState> emit) {
    _visible = false;
    _hiddenAt = DateTime.now().millisecondsSinceEpoch;
    _cancelTicker();
    final WorkoutTimerState s = state;
    if (s is WorkoutRestRunning) {
      _notifications.scheduleRestOver(s.endsAtMs);
    }
  }

  void _onAppShown(Emitter<WorkoutTimerState> emit) {
    _visible = true;
    _notifications.cancelRestOver();
    final WorkoutTimerState s = state;
    final bool hasTimer = s is WorkoutRestRunning || s is WorkoutWorkRunning;
    if (hasTimer) {
      _startTicker();
      // Fire one immediate tick (openGym's visibilitychange -> timerTick)
      _tick(emit);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Increments [flashId] only when [GymStateCubit.state.timerFlash] is true.
  /// ports useUI.js flashTimer() line 200.
  int _flash() {
    if (_gymState.state.timerFlash == true) {
      _flashCounter++;
    }
    return _flashCounter;
  }

  void _startTicker() {
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_visible) {
        add(const WorkoutTimerTicked());
      }
    });
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() async {
    _cancelTicker();
    _notifications.cancelRestOver();
    return super.close();
  }
}
