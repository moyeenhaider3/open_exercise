# Plan 03-16 Summary: Workout Screen, Start Flow, Active Workout & UI-07 Checklist

## Overview
Ported openGym's active workout screens and flows: `StartChooser`, `startFlow` with weigh-in routing, `ActiveWorkoutView` supporting Cards, List, and Compact views with superset grouping and gesture navigation, and completed the exhaustive UI-07 Zustand/update checklist covering all 30 Zustand actions and all in-scope `update()` closures with exact BLoC event mappings. Fully validated on Android emulator `emulator-5554` across all 7 comprehensive verification steps.

## Key Deliverables

1. **`startFlow` & `StartChooser` (`lib/features/workout/view/start_flow.dart`, `start_chooser.dart`)**:
   - `startFlow`: Implemented workout initiation helper checking user's `weighIn` preference (`'always'` -> `showWeighInSheet`, `'empty_only'` -> check today weigh-in, `'never'` -> start immediately), dispatching `WorkoutStarted`, and navigating to `/workout`.
   - `StartChooser`: Renders today's scheduled routines card, other available routines, freestyle workout launcher, and empty plan CTA ("Build your routine").
   - Integrated into `AppTabBar`: center tab button dynamically renders "Start" (green), "Workout" / "Resume" (orange pulsing disc) based on `GymState.active != null`, tapping dispatches start flow or resumes active workout.

2. **`WorkoutScreen` (`lib/features/workout/view/workout_screen.dart`)**:
   - Routes `WorkoutNone` -> `StartChooser` and `WorkoutRunning` -> `ActiveWorkoutView`.
   - Listens to all `WorkoutSignal`s:
     - `WorkoutStartedSignal` -> navigate to `/workout`
     - `WorkoutAllDoneSignal` -> `showWorkoutCompleteSheet`
     - `WorkoutToastSignal` -> `showToast`
     - `WorkoutFinishCheckSignal` -> `runFinishFlow` (checks completed sets)
     - `WorkoutFinishedSignal` -> `showFinishSummary` (renders locked completion modal with duration, volume, sets, PRs)

3. **`ActiveWorkoutView` (`lib/features/workout/view/active_workout_view.dart`)**:
   - Header with elapsed session time clock (`D-02a`), sets progress count (`{done}/{total} sets`), progress bar, workout view menu (`...`), and finish checkmark button.
   - Three layout modes:
     - **Cards mode**: Single exercise/superset unit per card with horizontal swipe gesture navigation (`onHorizontalDragUpdate`/`velocity`), bottom `< Prev` / `Next >` unit buttons, add exercise, and session note button.
     - **List mode**: Vertically scrolled list of all exercises and supersets with "Current" badge on active unit.
     - **Compact mode**: Ultra-dense layout without media/descriptions for fast gym logging.
   - **Superset Grouping**: Groups paired exercises inside a unified container with accent border, banner, and "Unpair" link.
   - Exercise menus: Add note, Details, History, Progression settings, Bar weight, Add warm-up set, Superset pairing (`Make superset with previous/next`), Swap exercise, Move up/down, and Remove exercise.

4. **UI-07 Action & Update Mapping Checklist (`.planning/phases/03-bloc-ui-translation/03-UI07-CHECKLIST.md`)**:
   - Cataloged all 30 Zustand actions from `useStore.js` and `useUI.js`.
   - Cataloged all 24 `update()` closures across openGym components (`Workout.jsx`, `RoutineEditor.jsx`, `ExConfigSheet.jsx`, `ExerciseDetail.jsx`, `History.jsx`, `Home.jsx`, `WeighInSheet.jsx`).
   - Mapped each action/update to its exact BLoC event class in `lib/features/**/bloc/*_event.dart`.
   - Verified that zero views make direct `.mutate()` or `saveState()` calls.

5. **Live Verification on Android Emulator (`emulator-5554`)**:
   - **Step 1 (Start flow & weigh-in)**: Tapped Start -> `StartChooser` -> selected Leg Day -> weigh-in sheet -> "Save & start workout" -> active workout opened.
   - **Step 2 (Set logging & extras)**: Bumped weight/reps, checked straight set (green check + badge), added warm-up set from menu, checked warm-up set, added drop set (sub-row with mini steppers), added rest-pause burst (sub-row with rest timer).
   - **Step 3 (Supersets & layout switching)**: Linked barbell full squat and romanian deadlift into superset ("Make superset with next"), verified green border and Unpair link. Switched layout to List (scrolled all exercises vertically), switched to Compact (dense set rows), switched back to Cards, and navigated between units via horizontal swipe.
   - **Step 4 (Progression settings)**: Opened exercise menu on sled 45° leg press, changed policy from Linear to Double progression, saved, and verified the progression guidance banner updated dynamically.
   - **Step 5 (Mid-session persistence)**: Killed process and relaunched app; home screen center tab bar showed orange glowing "Resume" button; tapping Resume restored active workout with all checked sets, warm-up, drop, burst, and superset pairing completely intact.
   - **Step 6 (Finish early & summary)**: Tapped finish checkmark -> "Finish early? 19 sets still unchecked" dialog -> confirmed "Finish workout" -> verified locked "Workout complete!" summary modal showing Duration (30 min), Volume (0 kg), Sets (2 sets · 1 work), PRs (—) -> tapped "Nice!" and cleanly returned to Home with Start button reset to green.
   - **Step 7 (Phase gates)**: QuickJS parity harness passed 205/205 (`tool/js04_audit.sh`), `flutter analyze` clean with 0 issues, 0 raw `ListView(` calls, 0 `.mutate()` calls in views, 0 test files created.

## Phase 3 Completion
With Plan 03-16 completed and verified, Phase 3 ("BLoC & UI Translation") is now 100% complete across all 16 plans.
