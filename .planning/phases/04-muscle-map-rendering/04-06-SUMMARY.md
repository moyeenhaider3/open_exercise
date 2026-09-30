# Plan 04-06 Summary: Muscles Screen & Muscle Explorer Widget

## Executive Summary
Plan `04-06` implemented the Muscle Explorer feature (MAP-03), providing the `/muscles` screen and a reusable `MuscleExplorer` component:
- **MusclesBloc**: Screen-scoped Bloc replicating `MuscleExplorer.jsx:18-44` filtering, search, equipment profiles, and pagination. Batches muscle indexing via `engine.muscleView.muscleIndex` (cached against `customEx` changes to avoid per-keystroke bridge calls). Reuses existing catalogue search, body-part filtering, equipment derivation, and favourites sorting.
- **Trailing Support in ChipStrip**: Added `final String? trailing;` to `ChipItem` and rendered trailing count strings in dim text with proper spacing.
- **MuscleExplorer Widget**: Built reusable `MuscleExplorer` displaying:
  - Equipment profile notice and toggle.
  - AppCard with `BodyMap` and a horizontally scrolling `ChipStrip` showing muscle names and catalogue exercise counts.
  - Interactive selection: tapping a muscle displays exercises that target it, search input, body part chips, equipment chips (when >1 options exist), favourites first, "Primary target" / "Also trains" tags, best weight indicators, "Plan" button to open routine sheet, detail sheet tap handler, empty state ("No match"), and "Show more" button in steps of 40.
  - Optional `onPick` support for embedding in picker dialogs.
- **MusclesScreen & Routing**:
  - Created `MusclesScreen` at `/muscles` with a back chevron leading to `/library`.
  - Added `AppRoutes.muscles = '/muscles'` in `app_router.dart` inside `ShellRoute`.
  - Added "By muscle" tinted `AppButton` in `LibraryScreen`'s header to navigate to `/muscles`.

---

## Changes Implemented

### 1. BLoC Pipeline
- `lib/features/muscles/bloc/muscles_event.dart`:
  - Defined sealed `MusclesEvent` with 8 subclasses (`MusclesStarted`, `MusclesGymStateChanged`, `MusclesMuscleTapped`, `MusclesQueryChanged`, `MusclesBodyPartSelected`, `MusclesEquipmentSelected`, `MusclesShowAllToggled`, `MusclesShowMoreRequested`).
- `lib/features/muscles/bloc/muscles_state.dart`:
  - Defined sealed `MusclesState` with `MusclesInitial` and `MusclesReady`.
- `lib/features/muscles/bloc/muscles_bloc.dart`:
  - `MusclesBloc` with sequential event processing, subscription to `GymStateCubit`, and cached `muscleIndex`.

### 2. UI & Routing
- `lib/core/ui_kit/chips.dart`:
  - Added optional `trailing` parameter to `ChipItem` and rendered it in `ChipStrip`.
- `lib/features/muscles/view/muscle_explorer.dart`:
  - Reusable explorer with equipment profile banner, `BodyMap`, muscle chips with counts, search, body-part and equipment filters, exercise list with primary/secondary labels and best weight tags.
- `lib/features/muscles/view/muscles_screen.dart`:
  - Screen at `/muscles` with back button to `/library`.
- `lib/core/router/app_router.dart`:
  - Registered `AppRoutes.muscles` and route in `ShellRoute`.
- `lib/features/library/view/library_screen.dart`:
  - Added "By muscle" button to `ScreenHeader`.

---

## Verification Results
- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS (0 forbidden imports or math operations).
- Exact acceptance criteria confirmed:
  - 8 event subclasses in `muscles_event.dart`.
  - Sequential transformer pattern and cached `muscleView.muscleIndex` without per-exercise bridge calls.
  - `ChipItem.trailing` added cleanly.
  - `AppRoutes.muscles` and `GoRoute` registered.
  - "By muscle" button wired in `LibraryScreen`.
  - All 9 required UI strings verified in `lib/features/muscles/view/`.
  - SPDX license headers present on all files.
