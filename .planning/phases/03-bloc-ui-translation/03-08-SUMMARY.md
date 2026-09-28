# Plan 03-08 Summary: ExConfig, ProgressionFields, GlyphPicker, AddToRoutine & BarWeightEditor

## Overview
Ported openGym's routine-exercise configuration sheet (`sheets.jsx` `ExConfig` and `ProgressionFields`), the routine icon/glyph picker (`glyphPicker`), the "Add to my plan" sheet (`AddToRoutine`), and the bar-weight editor (`BarWeightEditor` and `BarWeightSheet`). These sheets are pure presentation forms with local draft state that return values via callbacks or dispatch to existing Blocs (D-05, no sheet-stack Bloc).

## Key Deliverables
1. **Bar Weight Editor (`lib/features/library/view/bar_weight_editor.dart`)**:
   - `BarWeightEditor`: Ported from `sheets.jsx:582-622`. Reads `hasBarOverride`, `defaultBarWeight`, `isNoBar`, and `barWeightFor` from `BarJs`. Renders the `AppStepper` ('Bar ({0})', step 2.5), the 'No bar' `AppRow` with `AppSwitch`, and the three explanatory texts (with tap-to-reset for custom bar weights).
   - Dispatches `ExerciseBarWeightChanged` and `ExerciseNoBarChanged` to `ExercisesBloc`.
   - `showBarWeightSheet`: Modal sheet wrapping `BarWeightEditor`.
2. **Progression Fields (`lib/features/plan/view/sheets/progression_fields.dart`)**:
   - Ported `progressionStepOf` and `progressionStepIsValid` (input validation, not domain math). Step defaults from `defaultIncrement` or `defaultSecIncrement` via bridge (no hardcoded literals).
   - `ProgressionFields`: `SelectRow` for policy ("Follow the routine ({0})" plus `POLICIES_FOR` options), policy description, increment stepper, invalid-step alert (`palette.red`), and deload factor stepper bounded by `DELOAD_FACTOR_MIN` / `DELOAD_FACTOR_MAX`.
3. **Exercise Config Sheet (`lib/features/plan/view/sheets/ex_config_sheet.dart`)**:
   - `showExConfigSheet`: Ported from `sheets.jsx:1175-1426` `ExConfig`.
   - Seeded like openGym (`existing ?? initial ?? defaultConfig(ex.id)`). Double progression normalized via `RepRangeJs.normalizeRepRange`.
   - Dynamic controls for reps vs time mode (segmented button), sets, reps / rep-range, weight / extra bodyweight, duration/speed for cardio, bodyweight & per-side switches, warm-ups (bounded by `maxPlannedWarmups`), rest timer, notes, `ProgressionFields`, and `BarWeightEditor` (when `usesBar`).
   - Save / Delete buttons matching openGym (`showConfirmSheet` confirmation on delete).
4. **Glyph Picker Sheet (`lib/features/plan/view/sheets/glyph_picker_sheet.dart`)**:
   - `showGlyphPickerSheet`: Renders `kGlyphGroups` ('Strength', 'Equipment', 'Cardio', 'Recovery') with a `CustomScrollView` and a `SliverGrid` per group (UI-08). Highlights the current selection and returns picked icon.
5. **Add to Routine Sheet (`lib/features/plan/view/sheets/add_to_routine_sheet.dart`)**:
   - `showAddToRoutineSheet`: Shows target exercise title, `ListView.builder` of existing routines (glyph, name, exercise count, 'In routine' tag), and a 'New routine' row.
   - Dispatches `ExerciseAddedToRoutine` to `ExercisesBloc` upon completing `showExConfigSheet`. Documented contract that caller's `BlocListener` handles the toast and routine navigation.

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- Acceptance criteria verified:
  - 14 bridge calls across `ex_config_sheet.dart` and `progression_fields.dart` (`policyFor`, `normalizeRepRange`, `modeOf`, `isBw`, `isPerSide`, `defaultIncrement`, `weightIncrement`).
  - `showExConfigSheet` exported.
  - Zero `.mutate(` calls in `lib/features/plan/view` (sheets never write state directly; D-04).
  - Source citations to `sheets.jsx` present across files.
  - `BarWeightEditor` contains all 4 `BarJs` queries and dispatches both `ExerciseBarWeightChanged` and `ExerciseNoBarChanged`.
  - `ListView.builder` and `SliverGrid` used for list virtualization (UI-08).
