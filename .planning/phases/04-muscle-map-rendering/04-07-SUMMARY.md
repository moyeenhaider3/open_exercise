# Plan 04-07 Summary: Picker By-Muscle Mode, RoutineEdit & FinishSummary BodyMaps

## Executive Summary
Plan `04-07` wired the native `BodyMap` into all remaining openGym locations deferred from Phase 3 (UI07 checklist §4):
- **Exercise Picker By-Muscle Mode**: Added `byMuscle` state and toggle to `ExercisePickerCubit` and `ExercisePickerSheet`. Replaced the title with "Add exercise" (fixing earlier title drift) paired with an action button: tinted "By muscle" to switch into `MuscleExplorer(onPick: ...)`, and ghost "All" to return to standard list view. Selecting an exercise via `MuscleExplorer` cleanly invokes `onPick(ex, false, handle)`.
- **RoutineEdit "What this session hits"**: When the routine contains exercises, renders an `AppCard` displaying `BodyMap(levels: engine.muscles.levelsOf(engine.muscles.loadOfRoutine(routine)))` followed by the top 6 worked muscles as `_MuscleChip` widgets.
- **FinishSummary "What you just trained"**: In `showFinishSummary`, renders `BodyMap(levels: muscles.levelsOf(muscles.loadOfWorkouts(<Workout>[w])))` under the section heading "What you just trained" immediately before the "Nice!" button. Updated doc comment to remove the Phase 4 deferral note while retaining the Phase 5 audio cue note.
- Zero load or level arithmetic in Dart; all calculations invoke bridged `MusclesJs` functions.

---

## Changes Implemented

### 1. Exercise Picker
- `lib/features/library/bloc/exercise_picker_cubit.dart`:
  - Added `byMuscle` to `ExercisePickerState` and `byMuscleChanged(bool v)` to `ExercisePickerCubit`.
  - Preserved `byMuscle` in `_computeState`.
- `lib/features/library/view/exercise_picker_sheet.dart`:
  - Updated title to `Add exercise` with `By muscle` / `All` toggle button.
  - Rendered `MuscleExplorer(onPick: ...)` inside `BlocProvider<MusclesBloc>` when `byMuscle` is true.

### 2. RoutineEdit Coverage Card
- `lib/features/plan/view/routine_edit_screen.dart`:
  - Added imports for `BodyMap` and `MusclesJs`.
  - Added "What this session hits" `AppCard` with `BodyMap` and top 6 worked muscles.
  - Added private `_MuscleChip` widget matching openGym `.mchip` styling.

### 3. FinishSummary Workout Shading
- `lib/features/workout/view/sheets/finish_flow.dart`:
  - Added imports for `BodyMap` and `MusclesJs`.
  - Passed `MusclesJs` to `_FinishSummaryContent`.
  - Added "What you just trained" heading and `BodyMap` shaded with `muscles.levelsOf(muscles.loadOfWorkouts([w]))`.
  - Updated doc comment.

---

## Verification Results
- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS (0 forbidden imports or math operations).
- Exact acceptance criteria confirmed:
  - `byMuscle` and `byMuscleChanged` present in `exercise_picker_cubit.dart`.
  - `MuscleExplorer(`, `BlocProvider<MusclesBloc>`, and `onPick(ex, false, handle)` wired in `exercise_picker_sheet.dart`.
  - `What this session hits`, `loadOfRoutine(`, `take(6)`, and `BodyMap(` present in `routine_edit_screen.dart`.
  - `What you just trained`, `loadOfWorkouts(`, and `BodyMap(` present in `finish_flow.dart`.
  - No "deferred to Phase 4" remaining in `finish_flow.dart`.
  - Native `BodyMap` active across all 6 feature UI locations (Stats balance, fatigue, strength, MuscleExplorer, RoutineEdit, FinishSummary).
