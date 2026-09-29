# Plan 03-12 Summary: Workout Session Sheets & Finish Flow

## Overview
Ported all workout-session sheets from openGym `sheets.jsx` and `Workout.jsx`: weigh-in check-in, effort picker with presets and exact stepper, exercise/session notes, rename workout, add routine to session, exercise removal and superset chooser, swap choice for logged sets, and the workout finish flow with locked summary.

## Key Deliverables
1. **Weight Input & Weigh-In (`lib/features/workout/view/sheets/weight_input.dart`, `weigh_in_sheet.dart`)**:
   - `WeightInput`: Numeric input slider with +/- buttons and typed readout within W_LO..W_HI boundaries.
   - `showWeighInSheet`: Locked check-in sheet (`locked: true`) with sealed `WeighInResult` (saved, skipped, cancelled, chooseDifferent), seeded from `HistoryJs.lastBW`.
2. **Effort Picker (`lib/features/workout/view/sheets/effort_picker_sheet.dart`)**:
   - `showEffortPickerSheet`: Preset chips and rows via `EffortJs.presets`, colors mapped with `effortColor` and `AppPalette.cssVar`, values formatted with `toScale`, step buttons via `stepEffort`, and rating clearing.
3. **Session Notes, Rename & Mid-Workout Modifications (`lib/features/workout/view/sheets/`)**:
   - `exercise_note_sheet.dart`: Per-exercise note (today's note with pin toggle, standing note) bounded by `HistoryJs.noteMax`. Guarded by `BlocListener` to close if entry disappears. Dispatches `WorkoutExerciseNoteSaved`.
   - `session_note_sheet.dart`: Session-level note editor dispatching `WorkoutSessionNoteChanged`.
   - `rename_workout_sheet.dart`: Session renamer with `maxLength: 60`, Save disabled when empty, dispatching `WorkoutRenamed`.
   - `add_routine_to_session_sheet.dart`: Routine chooser with "already added" and "no exercises" validation tags, dispatching `WorkoutRoutineAddedToSession`.
   - `remove_exercise_sheet.dart`: Superset chooser `showRemoveExerciseChooser` and confirmation dialog `confirmRemoveExercise` dispatching `WorkoutExerciseRemoved`.
   - `swap_choice_sheet.dart`: Returns `SwapOptions?` for exercises with logged sets; handles superset group disposition ('keep' or 'detach') and regular swap confirmations.
4. **Finish Flow & Summary (`lib/features/workout/view/sheets/finish_flow.dart`)**:
   - `runFinishFlow`: Handles `WorkoutFinishCheckSignal`: asks 'Nothing logged yet' / 'Finish anyway' if 0 sets logged; asks 'Finish early?' if incomplete; dispatches `WorkoutFinishConfirmed`.
   - `showWorkoutCompleteSheet`: Center dialog when all sets are done offering 'Finish workout' (dispatches `WorkoutFinishRequested`) or 'Continue workout'.
   - `showFinishSummary`: Locked center dialog (`locked: true`) displaying duration, volume, sets (`setsDone` / `workSetsDone`), PR count, and PR / 1RM lines with capitalized names from `ExerciseCatalogue`. Navigates to `/home` via GoRouter.
   - Strictly conforms to D-02 (no timers or audio cues) and D-05 (native Flutter modals).

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- Acceptance criteria:
  - 6 facade calls in `effort_picker_sheet.dart` (≥ 5 required).
  - `locked: true` verified in `weigh_in_sheet.dart` and `finish_flow.dart`.
  - 4 weigh-in strings verified ('Quick check-in', 'Save & start workout', 'Start without weighing in', 'Choose a different workout').
  - 0 `.mutate(` calls in `lib/features/workout/view`.
  - 5 workout events dispatched across sheets.
  - `maxLength: 60` verified in `rename_workout_sheet.dart`.
  - 6 finish flow strings verified ('Nothing logged yet', 'Finish early?', 'Workout complete!', 'New PR:', 'Best estimated 1RM:', 'Nice!').
  - `setsDone` and `workSetsDone` called on `HistoryJs`.
  - 0 matches for BodyMap, beep, or vibrate in sheets.
