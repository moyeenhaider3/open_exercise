# Plan 03-14 Summary: Routine Edit BLoC, Routine Edit Screen & Superset Reordering

## Overview
Implemented the full Routine Edit feature suite porting openGym's `RoutineEdit.jsx`, including `RoutineEditBloc`, `RoutineEditEvent`, `RoutineEditState`, and `RoutineEditScreen` with `ReorderableListView.builder`, swipe-to-delete, superset pairing/unpairing via `JsEngineService`, equipment profile warning card, icon selection, and full routine copy/delete lifecycle. Built and verified on Android emulator `emulator-5554` across all 7 walkthrough steps, including explicit cold restart / force-stop persistence verification.

## Key Deliverables
1. **RoutineEditBloc (`lib/features/plan/bloc/routine_edit_bloc.dart`)**:
   - Manages state for routine editing: routine name, emoji glyph, progression override policy, deload exclusion toggle, superset units, equipment availability diagnostics, and exercise line formatting.
   - Delegates all domain math, superset grouping (`HistoryJs.supersetUnits`), pairing (`HistoryJs.pairAdjacent`), unpairing (`HistoryJs.unpairSuperset`), and unit moving to `JsEngineService` (JS-04).
   - Sequential event queue handling `RoutineRenamed`, `RoutineGlyphChanged`, `RoutineProgressionPolicyChanged`, `RoutineExcludeChanged`, `RoutineExerciseAdded`, `RoutineExerciseConfigured`, `RoutineExerciseRemoved`, `RoutineUnitMoved`, `RoutineUnitReordered`, `RoutineLinkToggled`, `RoutineCopied`, and `RoutineDeleted`.
   - Modifies persisted state exclusively via `GymStateCubit.mutate` (D-04).
2. **RoutineEditScreen (`lib/features/plan/view/routine_edit_screen.dart`)**:
   - Clean, reactive UI with `BlocConsumer<RoutineEditBloc, RoutineEditState>`.
   - Routine title field with live debounced rename and emoji glyph picker trigger.
   - Progression override selection row and deload progression exclusion toggle (`AppSwitch`).
   - Profile equipment warning card when exercises require unowned equipment.
   - `ReorderableListView.builder` for drag-and-drop reordering of exercises/superset units (UI-08 compliant).
   - Dismissible swipe-to-delete with red trash background for deleting exercises.
   - Green superset bracket border (`palette.acc`), superset badge label, and highlighted link button for contiguous superset units.
   - Unit move buttons (`chevronUp` / `chevronDown`) for moving individual exercises or full superset units.
   - Tap exercise card opens `showExConfigSheet` for configuring sets, reps, load, rest, and notes.
   - Footer with "Add exercise", "Copy routine", and "Delete routine" (with `showConfirmSheet` confirmation).
3. **Engine & Router Adjustments**:
   - `JsEngineService.call`: Added return of first argument for `cleanupSg` when JavaScript returns `undefined` due to in-place array mutation, ensuring null-safety in Dart.
   - `AppRoutes.routine`: Added `key: ValueKey<String>(id)` to `RoutineEditScreen` and `RoutineEditView` to ensure clean recreation of screen-local controllers and BLoCs on routine navigation.

## Device Verification Walkthrough (emulator-5554)
All 7 steps performed on physical/virtual hardware (`emulator-5554`):
1. **Loaded Starter Plan**: Loaded PPL starter plan on Plan screen (`14-step-1.png`). Push Day, Pull Day, and Leg Day appeared on schedule.
2. **Metadata Editing**: Renamed "Push Day" to "PHeavy Push", changed glyph to crest/shield, set progression to "Double progression", and switched Exclude from automatic progression toggle ON (`14-step-2.png`).
3. **Superset Linking, Moving & Deletion**:
   - Swiped "Dumbbell lateral raise" to delete it.
   - Tapped link icon on "Barbell incline bench press" to superset it with "Barbell bench press" above. Contiguous green border, "Superset" label, and highlighted link icon appeared.
   - Used unit move up button on "Dumbbell standing overhead press" to move it above the superset unit to the top of the routine (`14-step-3.png`).
4. **Exercise Configuration Sheet**: Tapped "Barbell incline bench press", opened `showExConfigSheet`, changed target sets from 3 to 5, and saved. Subtitle updated to `5 × 10` (`14-step-4.png`).
5. **Copy & Delete Routine**:
   - Tapped "Copy routine", verified new routine "PHeavy Push (Copy)" was created with all exercises and superset structures cloned (`after_tap_copy.png`).
   - Scrolled to footer, tapped "Delete routine", confirmed in confirmation bottom sheet, verified navigation back to Plan screen and confirmed "PHeavy Push (Copy)" was removed from database and UI (`14-step-5.png`).
6. **Force-Stop & Cold Relaunch Persistence Check**:
   - Force stopped app via `adb shell am force-stop com.example.open_exercise`.
   - Relaunched via `adb shell monkey -p com.example.open_exercise 1`.
   - Navigated to Plan tab, verified all modifications persisted: renamed "PHeavy Push", crest/shield glyph, Double progression, Deload exclusion toggle ON, Dumbbell standing overhead press at top, Barbell bench press + Barbell incline bench press superset intact, sets at 5 x 10, and deleted exercise remained absent (`14-step-6.png`).
   - **Persisted across restart: YES**.
7. **Visual Parity**: Layout, section card order, typography, superset badge styling, and colors match openGym's `RoutineEdit.jsx` (`14-step-7.png`).

## Quality & Compliance Gates
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS** (all math via `JsEngineService`).
- **UI-08 compliance**: Zero raw `ListView(` instances; all lists use `ReorderableListView.builder` or `ListView.builder`.
- Zero test files created.
