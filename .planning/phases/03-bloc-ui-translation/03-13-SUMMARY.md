# Plan 03-13 Summary: Library Screen, Detail Sheet, History Sheet & LineChart

## Overview
Implemented the full Library screen (`views/Library.jsx`), Exercise Detail sheet with 1RM calculator (`sheets.jsx:632-702`), Exercise History sheet (`sheets.jsx:704-752`), and the custom native SVG-style `LineChart` component (`components/LineChart.jsx`). Built and verified on Android emulator `emulator-5554` with network-disable offline cache testing.

## Key Deliverables
1. **LineChart (`lib/core/ui_kit/line_chart.dart`)**:
   - Native SVG-style `CustomPainter` ported directly from `components/LineChart.jsx`.
   - Scaled viewBox geometry (340 base width, padding left 34/8, right 12, top 10, bottom 22/8).
   - Domain padding (12% margin, degenerate ±1 widening, single-point duplication).
   - "Nice" y-step scaling using pure arithmetic powers of 10 without `pow(` (strictly adhering to JS-04 and audit rules).
   - Monthly and sub-month date tick marks, dashed goal lines with labels, smooth area gradient fill.
   - Interactive touch/drag tooltip showing date, formatted value, unit, and notes.
2. **Exercise History Sheet (`lib/features/library/view/exercise_history_sheet.dart`)**:
   - Memoized `ExerciseHistoryJs.exerciseHistory` caller.
   - Segmented toggle between Top set and Estimated 1RM curves.
   - `LineChart` rendered with 140 height in primary blue.
   - Virtualized `ListView.builder` listing sessions with `setLabel` formatting, PR badges, volume, and e1RM readouts.
3. **Exercise Detail Sheet (`lib/features/library/view/exercise_detail_sheet.dart`)**:
   - Name header with favourite star button wired to `ExerciseFavouriteToggled`.
   - `ExerciseMedia` integration with tap-to-pause and animated CDN playback.
   - Muscle/equipment badge tags, target muscle highlights, and descriptions.
   - Best / last session recap summary.
   - Action buttons: "Add to my plan" (`showAddToRoutineSheet`), "History" (`showExerciseHistorySheet`), custom exercise edit and delete (`showCustomExerciseSheet`, `confirmDeleteCustomExercise`).
   - Bar weight configuration (`BarWeightEditor`) when applicable.
   - OneRM calculator (`_OneRMSection`) using `OnermJs.estimate1RM`, `AppStepper`, and Epley formulas.
   - Numbered step-by-step English instructions.
4. **Library Screen (`lib/features/library/view/library_screen.dart`)**:
   - `CustomScrollView` with `ScreenHeader` displaying active catalogue size.
   - Search bar with typo-tolerant substring and search index dispatch.
   - Profile-based equipment toggle banner.
   - Body part and equipment `ChipStrip` filter rows.
   - Virtualized `SliverList.builder` containing "Create your own exercise" trigger and exercise list tiles.
   - Exercise items featuring `ExerciseThumb`, star indicators, muscle/equipment meta, best weight badges, and quick-add plan buttons.
   - Infinite scroll / pagination via "Show more" (`LibraryShowMoreRequested`).
   - `EmptyState` when queries return no match.

## Device Verification Walkthrough (emulator-5554)
All 6 steps performed on physical/virtual hardware (`emulator-5554`):
1. **Typo Search**: Tested query "dumbell bench" — correctly surfaced "Dumbbell bench press" at top with 1,324 total exercises header (`13-step-1.png`). Tested "sqat" yielding proper filtered results.
2. **Filter Chips**: Tapped "chest" chip and equipment chips — list filtered to matching items (Archer push up, Chest dips, etc., `13-step-2.png`). "All" cleanly cleared filters.
3. **Detail & Media**: Opened "Dumbbell bench press", GIF animated smoothly, tap toggled play/pause, favourite star triggered signal toast, estimated 1RM calculated accurately (`13-step-3.png`).
4. **Offline Media Cache Check**:
   - Disabled network via `adb shell svc wifi disable` and `adb shell svc data disable`.
   - Reopened exercise detail sheet.
   - **Served from ImageCache: YES** (`13-step-4.png`). Media rendered immediately from cache without errors. Network re-enabled afterwards.
5. **Custom Exercise Lifecycle**: Created "MyCustomExercise" via custom exercise sheet, verified in library list (`13-step-5.png`), opened detail sheet, opened delete dialog and confirmed deletion.
6. **openGym UI Parity**: Layout, section orders, typography, and styling verified against reference openGym web build.

## Quality & Compliance Gates
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS** (no `pow(` calls or domain math in Dart).
- **UI-08 compliance**: Zero raw `ListView(` instances across `lib/features/library/view/*.dart`; all lists use `ListView.builder` or `SliverList.builder`.
- Zero test files created.
