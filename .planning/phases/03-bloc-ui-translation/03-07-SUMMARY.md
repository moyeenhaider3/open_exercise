# Plan 03-07 Summary: WorkoutBloc Lifecycle, Session Events, and Flow Control Ports

## Overview
Implemented the app-scoped `WorkoutBloc` managing active workout lifecycle (start, finish, discard) and all 17 session-level events. Ported openGym's flow-control modules (`supersetFlow.js`, `active-workout-order.js`, `active-exercise-swap.js`) to pure Dart with source citations. Extended `HistoryJs` with bridged helpers for superset list operations. Wired `WorkoutBloc` into the global provider tree via `workoutBlocProviders`.

## Key Deliverables
1. **Flow Control Modules (`lib/features/workout/data/`)**:
   - `superset_flow.dart`: Ported `nextUnfinishedUnit`, `insertionIndexAfterCurrentUnit`, `setProgressHighWater`, and `supersetFlowStep`. (Rest timer functions omitted per D-02).
   - `active_workout_order.dart`: Ported `canMoveActiveWorkoutUnit` and `moveActiveWorkoutUnit` with index permutation tracking for high-water mark remapping.
   - `active_exercise_swap.dart`: Ported `swapActiveExercise` with `SwapOptions` handling logged set confirmations and superset group disposition (`keep` or `detach`).
2. **JS Bridge Extensions (`lib/core/js/modules/history_js.dart`)**:
   - Added `cleanupSgWorkoutEntries`, `pairAdjacentWorkoutEntries`, and `unpairSupersetWorkoutEntries` delegating list manipulations directly to QuickJS while preserving typed Dart `WorkoutEntry` lists.
3. **Workout BLoC Contract (`lib/features/workout/bloc/`)**:
   - `workout_event.dart`: 17 sealed events covering full lifecycle and session edits (`WorkoutStartRequested`, `WorkoutFinishRequested`, `WorkoutFinishConfirmed`, `WorkoutDiscarded`, `WorkoutRenamed`, `WorkoutSessionNoteChanged`, `WorkoutExerciseNoteSaved`, `WorkoutViewChanged`, `WorkoutUnitFocused`, `WorkoutUnitNavigated`, `WorkoutUnitMoved`, `WorkoutPaired`, `WorkoutUnpaired`, `WorkoutExerciseAdded`, `WorkoutExerciseSwapped`, `WorkoutExerciseRemoved`, `WorkoutRoutineAddedToSession`) plus internal `WorkoutGymStateChanged`.
   - `workout_state.dart`: Sealed `WorkoutState` with `WorkoutNone` and `WorkoutRunning` (with derived `cur`, `units`, `currentUnit`, `unitIdx`, `view`, `setsDone`, `setsTotal`, and `wc`), along with 5 one-shot signals (`WorkoutStartedSignal`, `WorkoutAllDoneSignal`, `WorkoutToastSignal`, `WorkoutFinishCheckSignal`, `WorkoutFinishedSignal`).
   - `workout_bloc.dart`: Sequential event execution, subscribing to `GymStateCubit.stream`. All state modifications write exclusively via `_gymState.mutate` (D-04). Workout building delegates to `SessionMergeJs.buildCombinedEntries` and completion to `FinishWorkoutJs.completeWorkout` (JS-04). Zero rest/work countdown timers (D-02).
4. **App Providers (`lib/app/providers/workout_providers.dart`)**:
   - Registered `BlocProvider<WorkoutBloc>` (`lazy: false`) with dependency injection from `context.read<GymStateCubit>()` and `deps.jsEngine`.

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- Acceptance criteria verified:
  - No `saveState` or `GymStateRepository` in `lib/features/workout` (D-04 single writer preserved).
  - 17 sealed event classes matching expected names in `workout_event.dart`.
  - At least 2 matches for `completeWorkout(` and `buildCombinedEntries(` in `workout_bloc.dart`.
  - Zero rest or work countdown timer matches in `lib/features/workout` (D-02 compliance).
  - `BlocProvider<WorkoutBloc>` wired in `workout_providers.dart`.
  - 7 pure flow-control function signatures matching openGym source citations.
