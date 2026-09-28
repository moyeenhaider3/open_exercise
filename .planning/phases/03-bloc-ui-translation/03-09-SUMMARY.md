# Plan 03-09 Summary: Exercise Media, Custom Exercises & Exercise Picker

## Overview
Ported exercise media components (`ExerciseMedia` and `ExerciseThumb` from `Media.jsx`), the custom exercise creation and deletion flow (`showCustomExerciseSheet` and `confirmDeleteCustomExercise` from `sheets.jsx:790-914`), and the exercise picker with sheet-scoped search and filter cubit (`showExercisePickerSheet` and `ExercisePickerCubit` from `sheets.jsx:907-1004`).

## Key Deliverables
1. **Exercise Media (`lib/features/library/view/exercise_media.dart`)**:
   - `ExerciseMedia`: Interactive animation player streaming from openGym's pinned jsDelivr CDN. Supports tap-to-pause / play, error fallback to still image and dumbbell placeholder with tap-to-retry, minimize/expand via `MediaSizeToggled` event to `ExercisesBloc`, and hidden when `S.gifSize == 'off'`.
   - `ExerciseThumb`: Static thumbnail for exercise lists with error fallback and cache bounding (`cacheWidth`).
   - Caching: Built on Flutter's default `PaintingBinding.instance.imageCache` in-memory LRU cache without third-party disk cache packages (UI-02).
2. **Custom Exercise Form & Delete Flow (`lib/features/library/view/custom_exercise_sheet.dart`)**:
   - `showCustomExerciseSheet`: Local-state form for creating or editing custom exercises. Seeds values with `hasExplicitMuscleMetadata` and `normalizeMuscleGroups`. Inputs for name, body part, equipment, primary muscles, secondary muscles, and description. Dispatches `CustomExerciseSaved` and awaits state transition before invoking callback.
   - `confirmDeleteCustomExercise`: Checks active workout constraints via `CustomExerciseDeleteRequested`, surfaces toasts or displays destruction confirmation dialog via `showConfirmSheet`, and dispatches `CustomExerciseDeleted`.
3. **Exercise Picker Cubit & Sheet (`lib/features/library/`)**:
   - `ExercisePickerCubit` (`bloc/exercise_picker_cubit.dart`): Sheet-scoped cubit managing search query, body part mode (including `'★'` used in plan/workout and `'☆'` favourites), equipment filter, and pagination (`shown`). Uses `searchExercises` for typo-tolerant searching and sorts favourites first.
   - `showExercisePickerSheet` (`view/exercise_picker_sheet.dart`): Bottom sheet with `SearchField`, body part and equipment `ChipStrip`s, "Create your own exercise" row, and `ListView.builder` with `ExerciseThumb`, usage indicators, quick-add '+' button, and row selection. Returns a `PickerHandle` for caller-controlled closing.

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- Acceptance criteria verified:
  - `Image.network` and `errorBuilder` implemented in `exercise_media.dart`.
  - `MediaSizeToggled` dispatched on minimize/expand.
  - Zero unmandated caching packages in `pubspec.yaml`.
  - `CustomExerciseSaved`, `CustomExerciseDeleteRequested`, `CustomExerciseDeleted` used in `custom_exercise_sheet.dart`.
  - `hasExplicitMuscleMetadata` and `normalizeMuscleGroups` called.
  - `searchExercises` encapsulated strictly within `exercise_picker_cubit.dart`.
  - `ListView.builder` used for picker virtualization (UI-08).
  - `'★'` and `'☆'` filtering modes implemented in cubit.
  - `PickerHandle showExercisePickerSheet` signature provided.
