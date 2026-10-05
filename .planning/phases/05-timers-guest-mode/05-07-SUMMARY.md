# 05-07 SUMMARY: WorkoutBloc Timer Integration, Timed Sets, and Audio Cues

**Phase:** 05-timers-guest-mode  
**Plan:** 07  
**Status:** ✅ Complete  
**Date:** 2026-09-30

## What was done

### Task 1: WorkoutBloc rest/work integration, beeps, timed-set events, provider wiring

1. **`lib/features/workout/bloc/workout_event.dart`:**
   - Added `WorkoutTimedSetStarted(int entryIdx, int setIdx)`: dispatched on tapping the Start (play) button on timed set rows.
   - Added `WorkoutTimedSetLogged(int entryIdx, int setIdx, int elapsedSec)`: dispatched when work timer completes to record elapsed seconds.

2. **`lib/features/workout/bloc/workout_bloc.dart`:**
   - Injected `WorkoutTimerBloc` and `TimerSound` via constructor.
   - Subscribed to `WorkoutTimerBloc.stream` for `WorkoutTimerWorkDone` signal and dispatched `WorkoutTimedSetLogged`. Canceled subscription in `close()`.
   - Added private helpers `_startRest`, `_stopRest`, `_stopWork`, `_restRunning`, `_workRunning`. Guarded `_startRest` against backfilled workouts (`active?.extra['backfill'] != null`).
   - Wired `_onSetToggled`:
     - Emits sound cue `_sound.beep(snd, 1040, 0.12)` and `_sound.vibrate(30)` on check.
     - Computes rest requirements via `_engine.supersetFlow.restSecFor`, `warmupRestSecFor`, `restOnRecheck`, and `restAfterSet`.
     - Supports singleton exercises, superset round/unit steps, and warm-up set checks without Dart math.
   - Wired `_onTimedSetStarted`: initiates hold timer via `WorkoutWorkStarted` with target duration and exercise display name.
   - Wired `_onTimedSetLogged`: updates elapsed seconds on set row and triggers standard toggle logic if set is not already done.
   - Wired list mutation timer bookkeeping:
     - `_onExerciseRemoved`: `WorkoutRestExerciseRemoved(idx)`.
     - `_onExerciseAdded`: `WorkoutRestOwnerShifted(insertAt, 1)`.
     - `_onUnitMoved`: guards against running work timers and emits `WorkoutRestOwnerRemapped(moved.indices)`.
     - `_onExerciseSwapped`: stops work and rest timers.
     - `_onDiscarded`, `_onStartRequested`, `_onBackfillStarted`: stops rest and work timers.
     - `_onFinishConfirmed`: stops rest and plays completion fanfare beeps (880 Hz, 1100 Hz, 1320 Hz).
   - Removed all `D-02: rest timer is Phase 5` and `D-02: beep / vibrate dropped` deferral markers.

3. **`lib/app/providers/workout_providers.dart`:**
   - Supplied `WorkoutTimerBloc` and `deps.timerSound` to `WorkoutBloc`.

4. **`lib/features/workout/data/superset_flow.dart`:**
   - Updated header note documenting delegation of rest logic to `SupersetFlowJs`.

### Task 2: Timed-set Start button, header spacer, finish-flow note

1. **`lib/features/workout/view/widgets/set_row.dart`:**
   - Replaced Phase 3 deferral comment with `AppIconButton('play', tooltip: t('Start set'), small: true)`.
   - Listens to `WorkoutTimerBloc` state; disabled if set is done or another work timer is running.
   - Dispatches `WorkoutTimedSetStarted`.

2. **`lib/features/workout/view/widgets/exercise_block.dart`:**
   - Added header spacer (`if (view.timed) const SizedBox(width: 32.0)`) matching openGym `.ck-sp` alignment.

3. **`lib/features/workout/view/sheets/finish_flow.dart`:**
   - Replaced deferred audio cue comment with citation indicating finish beeps occur in `WorkoutBloc._onFinishConfirmed`.

## Verification & Parity

- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS.
- `bash tool/guest_audit.sh`: PASS.
- All Phase 5 deferral markers eliminated from `lib/features/workout`.
