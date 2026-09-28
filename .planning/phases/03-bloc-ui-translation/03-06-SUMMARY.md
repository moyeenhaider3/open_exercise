# Plan 03-06 Summary: App Shell, Route Table & Bottom TabBar

## Overview
Implemented openGym's navigation frame: the `go_router` route table from `App.jsx`, the custom 5-tab `AppTabBar` from `TabBar.jsx` with active workout tracking, `ShellPage`, and stable screen route targets for Waves 3–5.

## Key Deliverables
1. **Route Table (`lib/core/router/app_router.dart`)**:
   - `AppRoutes`: `home` (`/home`), `plan` (`/plan`), `routine` (`/plan/r/:id`), `workout` (`/workout`), `stats` (`/stats`), `library` (`/library`), and helper `routinePath(id)`.
   - Root `/` and unknown routes redirect to `/home`.
   - Plain `ShellRoute` (not `StatefulShellRoute` or `IndexedStack`) remounts screens when switching tabs, resetting screen-local browse state just like openGym's React Router.
2. **Screen Route Targets**:
   - `HomeScreen` (`lib/features/home/view/home_screen.dart`): Phase 3.1 (D-01).
   - `StatsScreen` (`lib/features/stats/view/stats_screen.dart`): Phase 3.1 (D-01).
   - `LibraryScreen` (`lib/features/library/view/library_screen.dart`): Plan 03-13.
   - `PlanScreen` (`lib/features/plan/view/plan_screen.dart`): Plan 03-11.
   - `RoutineEditScreen` (`lib/features/plan/view/routine_edit_screen.dart`): Plan 03-14.
   - `WorkoutScreen` (`lib/features/workout/view/workout_screen.dart`): Plan 03-16.
3. **Shell & Navigation Bar (`lib/features/shell/view/*`)**:
   - `ShellPage`: Embeds `SafeArea` body and `AppTabBar` bottom navigation bar.
   - `AppTabBar`: Port of `TabBar.jsx`.
     - 5 tabs: Home (`house`), Plan (`calendar`), Start (centre circle), Stats (`chart`), Exercises (`list`).
     - Active tab resolution: maps `history` to `stats`, `settings` to `home`, `muscles` to `library`.
     - Centre Start button: Uses `BlocSelector<GymStateCubit, GymState, bool>` on `state.active != null`.
       - Inactive: label `t('Start')`, icon `'dumbbell'`, accent disc.
       - Active (not on `/workout`): label `t('Resume')`, icon `'play'`, orange disc with pulsing ring animation.
       - Active (on `/workout`): label `t('Workout')`, icon `'dumbbell'`, orange disc.

## Verification
- `flutter analyze`: **No issues found!**
- `bash tool/js04_audit.sh`: **JS-04 audit: PASS**
- `flutter build apk --debug`: **Succeeded** (`✓ Built build/app/outputs/flutter-apk/app-debug.apk` in 14.8s).
- Acceptance criteria verified:
  - Route constants: 6 (`home`, `plan`, `routine`, `workout`, `stats`, `library`).
  - Plain `ShellRoute` used; no `StatefulShellRoute`.
  - All 6 screen files verified present.
  - TabBar icon set: 6 unique keys (`house`, `calendar`, `chart`, `list`, `dumbbell`, `play`).
  - Start button labels: 3 (`'Start'`, `'Resume'`, `'Workout'`).
