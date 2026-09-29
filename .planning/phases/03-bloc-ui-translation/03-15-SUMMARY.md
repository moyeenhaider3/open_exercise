# Plan 03-15 Summary: Exercise Block & Set Row Logging Widgets

## Overview
Ported openGym's active workout set-logging and exercise display architecture from `Workout.jsx` lines 76-495 into four modular, pure view widgets: `SetRow`, `SideRows`, `SetSubRows`, and `ExerciseBlock`. The widgets project pre-computed derivations from `WorkoutEntryView` and dispatch `WorkoutBloc` events without any local state mutation, timer loops, or JS engine dependencies.

## Key Deliverables

1. **`SetRow` (`lib/features/workout/view/widgets/set_row.dart`)**:
   - Renders individual work/warm-up set rows with phase-numbered circular indicator button.
   - Set menu bottom sheet (`showMenuSheet`): Drop set ('+ Drop'), Rest-pause burst ('+ Burst'), and Remove this set (danger, disabled when single set remains).
   - Dynamic columns (w, r, min, sec, speed) supporting stepper increments or direct numeric input based on `WorkoutControls.steppers`.
   - Dedicated effort cell (`_EffortCell`): tinted by `effortColorToken` (`AppPalette.cssVar`), stepping via `WorkoutSetFieldBumped` or opening `showEffortPickerSheet` (concluding set if uncompleted).
   - Done checkbox (`AppCheck`) dispatching `WorkoutSetToggled`.
   - Warm-up phase headers ('Warm-up') and phase transition divider hairlines matching openGym source order.
   - Timed sets omit "Start set" hold button per D-02 (deferred to Phase 5 TMR-01).

2. **`SideRows` (`lib/features/workout/view/widgets/side_rows.dart`)**:
   - Renders unilateral exercises with stacked L/R limb sub-rows.
   - Phase-numbered set indicator button with full set menu sheet.
   - 'L' and 'R' limb badges styled with accent background when completed.
   - Independent numeric inputs and steppers per limb dispatching `WorkoutSideFieldChanged` and `WorkoutSetFieldBumped(side: 'L'|'R')`.
   - Side-specific effort cells and done checkboxes dispatching `WorkoutEffortPicked(side: ...)` and `WorkoutSetToggled(side: ...)`.
   - Renders limb-specific drop and burst extras via `SetSubRows(side: 'L'|'R')`.

3. **`SetSubRows` (`lib/features/workout/view/widgets/set_sub_rows.dart`)**:
   - Renders drop sets (`Drop {0}`) with mini steppers for weight (stepping via `loadStep`) and reps, and remove button (`WorkoutDropRemoved`).
   - Renders rest-pause bursts (`Burst {0}`) with mini stepper for reps, rest seconds indicator (`{n}s`), and remove button (`WorkoutBurstRemoved`).
   - Shortcut chips (`+ Drop`, `+ Burst`) displayed when `wc.setShortcuts` is enabled.

4. **`ExerciseBlock` (`lib/features/workout/view/widgets/exercise_block.dart`)**:
   - Composes full exercise interface:
     - `ExerciseMedia` player (minimizable, omitted in dense view).
     - Title header with exercise name, note icon button (`showExerciseNoteSheet`), and more button (`showMenuSheet`).
     - More menu items: Add/Edit note, Details (`onShowDetail`), History (`onShowHistory`), Progression settings (`onProgressionSettings`), Bar weight (`showBarWeightSheet`), Add warm-up set, Superset pairing (`onPairPrev`/`onPairNext`), Swap exercise (`onSwap`), Move up/down (`onMoveUp`/`onMoveDown`), and Remove exercise (`onRemoveExercise`).
     - Tags row: Cardio, Per side, Target muscle, Equipment, and Best weight.
     - Standing fact notes, pinned notes from prior workouts (yellow flag), and today's session note.
     - 'Last time' summary line with set performance details.
     - Barbell & plate loading guidance line with barbell icon.
     - Automatic progression guidance line with directional icon and deload styling.
     - Sets card container with aligned column headers and bounded set list (UI-08 compliant).
     - Card footer buttons: 'Add warm-up set', 'Remove set', and 'Add set' (or lean 'Add set' when shortcuts disabled).

5. **Model & Architecture Enhancements**:
   - `WorkoutEntryExtras`: Added `d` getter to access historical workout date from `WorkoutEntry.extra`.
   - `ProgressionGuidance`: Added `kind` field to convey progression direction ('up', 'deload') to UI widgets without requiring direct imports of internal progression models.
   - `MenuItemSpec`: Added `disabled` flag support to cleanly reflect disabled actions in openGym menu sheets.
   - `WorkoutBloc._onSetFieldBumped`: Added `_engine.history.stepEffort` delegation for `rir` and `rpe` fields.

## Quality & Compliance Gates
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **PASS** (all domain logic through JS).
- **UI-08 compliance**: Sets within an exercise block are bounded (rendered in Column); list of blocks in Plan 03-16 uses `ListView.builder`. Zero raw `ListView(` calls.
- Zero test files created.
