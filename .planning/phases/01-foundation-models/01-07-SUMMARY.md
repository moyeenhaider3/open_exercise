---
phase: 01-foundation-models
plan: 07
subsystem: ui
tags: [flutter_bloc, go_router, material3, theming, sealed-classes, di, sqflite-bootstrap]

# Dependency graph
requires:
  - phase: 01-foundation-models (Plan 01-04)
    provides: "GymState (theme/accent fields, defaultTheme='dark'/defaultAccent='lime', copyWith)"
  - phase: 01-foundation-models (Plan 01-05)
    provides: "ApiClientFactory / OpenGymApiClient wrapper"
  - phase: 01-foundation-models (Plan 01-06)
    provides: "GymStateRepository (loadState/saveState), AppDatabase.open/defaultPath"
provides:
  - "lib/core/theme/{accents,app_theme}.dart: openGym's 8 accents + Material 3 ThemeData builder"
  - "lib/features/shell/{data,bloc,view}: ThemeSettings mapper, sealed ShellEvent/ShellState, ShellBloc, empty ShellPage"
  - "lib/core/router/app_router.dart: createAppRouter()/AppRoutes (go_router)"
  - "lib/app/{dependencies,app}.dart: AppDependencies + OpenExerciseApp composition root (MultiRepositoryProvider + BlocProvider + themed MaterialApp.router)"
  - "lib/main.dart: real bootstrap (AppDatabase.open at defaultPath -> DI -> runApp), counter template removed"
affects: ["Phase 2 (Blocs plug into this shell/DI pattern)", "Phase 3 (screens register routes on top of AppRoutes/createAppRouter and replace ShellPage's empty body)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sealed Bloc state/event pair per feature (ShellEvent/ShellState), widgets only dispatch events, all logic lives in the Bloc (FND-01)"
    - "GoRouter created exactly once per app lifetime (State field in a StatefulWidget), not rebuilt on every BlocBuilder emission, so navigation state survives theme changes"
    - "RepositoryProvider/MultiRepositoryProvider is the only DI mechanism (no get_it), per Research A5"
    - "A Bloc's own load path always degrades to safe defaults on any failure (loadState throws, or returns null) rather than ever leaving the app stuck on an initial/loading state -- 'the shell must always boot' (T-1-12)"

key-files:
  created:
    - lib/core/theme/accents.dart
    - lib/core/theme/app_theme.dart
    - lib/features/shell/data/theme_settings.dart
    - lib/features/shell/bloc/shell_event.dart
    - lib/features/shell/bloc/shell_state.dart
    - lib/features/shell/bloc/shell_bloc.dart
    - lib/core/router/app_router.dart
    - lib/features/shell/view/shell_page.dart
    - lib/app/dependencies.dart
    - lib/app/app.dart
  modified:
    - lib/main.dart

key-decisions:
  - "No test/ files created (project no-tests rule, CLAUDE.md/STATE.md precedence, hook-enforced). test/features/shell/bloc/shell_bloc_test.dart, test/features/shell/view/shell_page_test.dart and test/architecture/layout_test.dart were never written. Substituted: (1) a manual code-trace of every <behavior> assertion against flutter-analyze-verified deterministic branching logic (Task 1), (2) grep/find one-liners reproducing every rule test/architecture/layout_test.dart would have enforced (Task 3), (3) a real end-to-end boot on the connected Android emulator (flutter build apk --debug -> adb install -> am start -> screencap), which is stronger evidence for FND-05 than a widget test would have been since it exercises the real platform channel (sqflite plugin) and Gradle/AGP toolchain, not just the Dart VM."
  - "test/widget_test.dart deleted (git rm), per this plan's explicit Task 3 instruction and the no-tests rule's stated exception -- it referenced the removed counter MyApp and broke flutter analyze once lib/main.dart was replaced."

patterns-established:
  - "Any later feature Bloc (Phase 2+) should follow ShellBloc's shape exactly: sealed *Event/*State files, one on<> handler per event, and a private _loadOrDefaults()-style safe-degradation helper for any handler that reads persisted state."
  - "lib/app/app.dart is the single place MaterialApp.router/theme/routerConfig are constructed; feature code never builds its own MaterialApp."

requirements-completed: [FND-01, FND-05]

# Metrics
duration: ~50min
completed: 2026-09-25
---

# Phase 1 Plan 07: Themed Shell, ShellBloc, go_router and App Bootstrap Summary

**openGym's 8-accent Material 3 theme wired end-to-end through a sealed-state `ShellBloc` (backed by `GymStateRepository`) into a `go_router`/`MultiRepositoryProvider` composition root, replacing the counter template with a real `AppDatabase.open` bootstrap -- verified booting to an empty dark Material 3 shell on a live Android emulator.**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-09-25
- **Tasks:** 3/3 (Task 1's `tdd="true"` test-file step skipped per no-tests rule)
- **Files modified:** 11 (10 new, 1 replaced: `lib/main.dart`)

## Accomplishments
- `lib/core/theme/accents.dart`: `kAccents` -- openGym's 8 accent colours ported 1:1 from `../openGym/frontend/src/lib/format.js:94` (lime `0xFF30D158`, sky `0xFF0A84FF`, orange `0xFFFF9F0A`, violet `0xFFBF5AF2`, pink `0xFFFF375F`, red `0xFFFF453A`, teal `0xFF40C8E0`, gold `0xFFFFD60A`), `kDefaultAccentKey = 'lime'`.
- `lib/core/theme/app_theme.dart`: `buildAppTheme(Brightness, Color)` -- Material 3 `ThemeData`, `ColorScheme.fromSeed(...).copyWith(primary: accent)` (so `colorScheme.primary` is always exactly the requested accent, never a seed-derived approximation), background `#000000` dark / `#F2F2F7` light (`../openGym/frontend/src/App.jsx:57`).
- `lib/features/shell/data/theme_settings.dart`: `ThemeSettings` -- maps `GymState.theme`/`.accent` strings to `ThemeMode`/`Color`, falling back to `dark`/`lime` for any unrecognised value (`ThemeSettings.fromState`), plus the inverse `themeModeToOpenGym` for persistence and a `const ThemeSettings.defaults()`.
- `lib/features/shell/bloc/{shell_event,shell_state,shell_bloc}.dart`: sealed `ShellEvent` (`ShellStarted`, `ShellThemeChanged`, `ShellAccentChanged`) and sealed `ShellState` (`ShellInitial`, `ShellReady`); `ShellBloc` loads via `GymStateRepository.loadState`/persists via `.saveState`, and its `_loadOrDefaults()` helper degrades to `GymState.defaults()` on *any* load failure (not just at boot) so a transient DB error never gets a handler stuck.
- `lib/core/router/app_router.dart`: `createAppRouter()` (single `GoRoute('/')` to `ShellPage`), `AppRoutes.shell` for Phase 3 to extend.
- `lib/features/shell/view/shell_page.dart`: empty `Scaffold` (`key: Key('shell-scaffold')`, `AppBar(title: 'openGym')`, `SizedBox.shrink()` body) -- no demo content, per FND-05.
- `lib/app/dependencies.dart` + `lib/app/app.dart`: `AppDependencies` (repository + API client factory) provided through `MultiRepositoryProvider`; `OpenExerciseApp` is a `StatefulWidget` so its `GoRouter` is built exactly once and survives `ShellBloc` rebuilds; `BlocBuilder<ShellBloc, ShellState>` exhaustively switches the sealed state into a themed `MaterialApp.router`.
- `lib/main.dart`: counter template fully replaced -- `WidgetsFlutterBinding.ensureInitialized()` -> `AppDatabase.open(factory: databaseFactory, path: AppDatabase.defaultPath())` -> `runApp(OpenExerciseApp(...))`. No `get_it` (confirmed absent from `pubspec.yaml`).
- `flutter analyze` (whole project): "No issues found!"
- `flutter build apk --debug`: succeeded (`build/app/outputs/flutter-apk/app-debug.apk`).
- **Real-device FND-05 verification**: installed the built debug APK on the connected `emulator-5554` Android emulator, launched `com.example.open_exercise/.MainActivity`, confirmed via `adb logcat` no `FATAL`/`AndroidRuntime` exception for the app, and captured a screenshot (`adb exec-out screencap -p`) showing the app boots to an empty **dark** Material 3 shell with an `AppBar` titled **"openGym"** and no body content -- exactly the FND-05/must-haves spec (dark background `#000000`, `lime` default accent since no prior state existed for `kLocalGuestUid` on a fresh install). App was then force-stopped and uninstalled from the emulator (throwaway verification, nothing committed to the repo beyond the source files).

## How FND-01/FND-05 were verified (no-tests rule)

Per the project's mandatory no-tests rule, no file was created under `test/` for this plan (the PreToolUse hook also blocks any such write). Substitutions:

**Task 1 behavior (`ThemeSettings`/`ShellBloc` `<behavior>` assertions)** -- verified by manual code trace against `flutter analyze`-checked, deterministic branching logic (no async races, no external I/O beyond the already-verified `GymStateRepository` from Plan 01-06):
1. No stored state for `kLocalGuestUid` -> `_loadOrDefaults()` returns `GymState.defaults()` (`theme='dark'`, `accent='lime'` per `default_state.dart:24-25`) -> `ShellReady(dark, lime)`. Matches.
2. Stored `theme:'light', accent:'sky'` -> `ThemeSettings.fromState` maps `'light'`->`ThemeMode.light`, `'sky'` is in `kAccents` -> kept. `'system'` -> `ThemeMode.system` (explicit switch case). Matches.
3. Unknown `theme:'blue'` hits the switch's `default` case -> `ThemeMode.dark`; unknown `accent:'neon'` fails `kAccents.containsKey` -> `kDefaultAccentKey='lime'`. Matches.
4. `ShellThemeChanged('light')`: `current.copyWith(theme: 'light')` -> `saveState(uid, next)` called with `next.theme=='light'` -> `emit(ShellReady(ThemeSettings.fromState(next)))` -> `themeMode == ThemeMode.light`. Matches.
5. `ShellAccentChanged('gold')`: same path with `accent`; `'gold'` is in `kAccents` -> kept as-is, persisted via `saveState`. Matches.
6. `_loadOrDefaults()` wraps `repository.loadState(uid)` in `try/catch`, returning `GymState.defaults()` on any thrown error -- used uniformly by all three event handlers, so a load failure during `ShellStarted` *or* a later theme/accent change both still emit `ShellReady` (T-1-12, "the shell must always boot"). Matches (and is more defensive than the plan strictly required for the change-event handlers).
7. `kAccents` has exactly 8 entries with the exact ARGB values -- confirmed by `grep -cE` (see Acceptance Criteria below), not just trace.
8. `buildAppTheme(Brightness.dark, kAccents['lime']!)`: `useMaterial3: true` always; `colorScheme.primary` is exactly `accent` (via `.copyWith(primary: accent)`, overriding whatever `ColorScheme.fromSeed` would have derived) == `Color(0xFF30D158)`; `scaffoldBackgroundColor` == `Color(0xFF000000)` (dark) / `Color(0xFFF2F2F7)` (light). Matches.

**Task 3 architecture rules (what `test/architecture/layout_test.dart` would have enforced)** -- reproduced as shell one-liners, all run for real against the actual tree:

```
$ for d in api db data models theme router; do [ -d "lib/core/$d" ] && echo OK || echo MISSING; done
OK OK OK OK OK OK   # lib/core/{api,db,data,models,theme,router} all exist

$ for d in lib/features/*/; do for sub in data bloc view; do [ -d "${d}${sub}" ] && echo OK || echo MISSING; done; done
OK OK OK   # lib/features/shell/{data,bloc,view} all exist

$ for f in lib/features/*/bloc/*_state.dart; do grep -qE 'sealed class \w+State extends Equatable' "$f" && echo OK || echo FAIL; done
OK   # lib/features/shell/bloc/shell_state.dart

$ for f in lib/features/*/bloc/*_event.dart; do grep -qE 'sealed class \w+Event extends Equatable' "$f" && echo OK || echo FAIL; done
OK   # lib/features/shell/bloc/shell_event.dart

$ find lib -type f -name "*.dart" ! -path "lib/core/api/generated/*" ! -name "*.g.dart" -print0 \
  | while read -r -d '' f; do [ "$(head -1 "$f")" = "// SPDX-License-Identifier: AGPL-3.0-or-later" ] || echo "FAIL: $f"; done
Checked 23 files, 0 missing SPDX header
```

**Task 3 FND-05 boot** (what `test/features/shell/view/shell_page_test.dart` would have exercised in-process) -- exercised on a real device instead, which is strictly stronger evidence since it goes through the real `sqflite` platform channel and the actual Gradle/AGP Android build, not a `flutter_test` fake binding:

```
$ flutter build apk --debug                              # exit 0, "Built build/app/outputs/flutter-apk/app-debug.apk"
$ adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk   # Success
$ adb -s emulator-5554 shell am start -n com.example.open_exercise/.MainActivity
$ adb -s emulator-5554 shell dumpsys activity activities | grep mFocusedApp
  mFocusedApp=ActivityRecord{... com.example.open_exercise/.MainActivity ...}
$ adb -s emulator-5554 logcat -d | grep -iE "com.example.open_exercise.*FATAL|AndroidRuntime.*open_exercise"
  (no output -- no crash)
$ adb -s emulator-5554 exec-out screencap -p > shell-boot.png
  # screenshot confirms: black background, AppBar "openGym", empty body -- exactly the empty dark Material 3 shell
```
App was then `am force-stop` + `uninstall`ed from the emulator; the APK under `build/` is gitignored (`/build/` in `.gitignore`) and was never committed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Accent palette, app theme, ThemeSettings mapper and ShellBloc (sealed states/events)** - `91b6642` (feat)
2. **Task 2: go_router, empty ShellPage, DI composition root and bootstrap in main.dart** - `69d198a` (feat)
3. **Task 3: Widget boot test, layout/convention test and removal of the template test** - `68ec18d` (chore) -- test-file portions skipped per no-tests rule; only the template deletion landed as a commit (see Deviations)

**Plan metadata:** this SUMMARY commit (docs)

## Files Created/Modified
- `lib/core/theme/accents.dart` - `kAccents`, `kDefaultAccentKey`
- `lib/core/theme/app_theme.dart` - `buildAppTheme(Brightness, Color)`
- `lib/features/shell/data/theme_settings.dart` - `ThemeSettings` (fromState/defaults/themeModeToOpenGym)
- `lib/features/shell/bloc/shell_event.dart` - sealed `ShellEvent` (`ShellStarted`/`ShellThemeChanged`/`ShellAccentChanged`)
- `lib/features/shell/bloc/shell_state.dart` - sealed `ShellState` (`ShellInitial`/`ShellReady`)
- `lib/features/shell/bloc/shell_bloc.dart` - `ShellBloc`
- `lib/core/router/app_router.dart` - `createAppRouter()`, `AppRoutes`
- `lib/features/shell/view/shell_page.dart` - `ShellPage`
- `lib/app/dependencies.dart` - `AppDependencies`
- `lib/app/app.dart` - `OpenExerciseApp`
- `lib/main.dart` - real bootstrap (replaces counter template)

## Decisions Made
- See "No test/ files created" under frontmatter `key-decisions` -- test-writing steps replaced with manual code-trace + grep/find substitutes + a real-device boot, per the project's no-tests rule.
- `ShellBloc._loadOrDefaults()` is used by *all three* event handlers (not just `ShellStarted`), so a transient repository failure during a theme/accent change also degrades safely instead of only being handled at boot -- a deliberate strengthening of T-1-12's mitigation, not scope creep (same file, same task).
- `OpenExerciseApp` is a `StatefulWidget` (plan allowed either a field or `State`) specifically so `GoRouter` survives `ShellBloc` rebuilds without resetting navigation.

## Deviations from Plan

### Rule-driven adjustments (no-tests project rule, CLAUDE.md/STATE.md precedence)

**1. [No-tests project rule] `test/features/shell/bloc/shell_bloc_test.dart`, `test/features/shell/view/shell_page_test.dart` and `test/architecture/layout_test.dart` not created**
- **Found during:** Task 1 (`tdd="true"`) and Task 3
- **Issue:** All three specify writing test files (bloc_test/mocktail for Task 1; flutter_test widget test and a pure-`dart:io` architecture test for Task 3). The no-tests rule and its PreToolUse hook forbid any write under `test/`, and `bloc_test`/`mocktail`/`sqflite_common_ffi` are forbidden dev-dependencies.
- **Fix:** Implemented only production code. Task 1's `<behavior>` assertions were verified by manual code trace (deterministic branching logic, backed by a clean `flutter analyze`). Task 3's architecture rules were reproduced as one-off shell/grep/find commands run directly against the real tree (not committed anywhere). Task 3's FND-05 boot assertion was verified more strongly than a widget test could: a real `flutter build apk --debug` + install + launch + screenshot on the connected Android emulator, confirmed via `adb logcat` that no crash occurred and via screenshot that the empty dark Material 3 shell renders exactly as specified.
- **Files affected:** none under `test/` created; `test/widget_test.dart` deleted (see Deviation 2, not a fix -- an explicit plan instruction).
- **Verification:** see "How FND-01/FND-05 were verified" above for full commands and results.
- **Committed in:** `91b6642` (Task 1), `69d198a` (Task 2, no test steps to begin with), `68ec18d` (Task 3 -- template deletion only)

**2. [Explicit plan instruction, not a rule-driven deviation] `test/widget_test.dart` deleted via `git rm`**
- **Found during:** Task 3
- **Issue:** The template counter test references the now-removed `MyApp`/`MyHomePage` classes and broke `flutter analyze`.
- **Fix:** Deleted per this plan's own Task 3 action step and the no-tests rule's stated exception (deleting is allowed; writing is not).
- **Files affected:** `test/widget_test.dart` (removed)
- **Verification:** `flutter analyze` clean afterwards.
- **Committed in:** `68ec18d`

---

**Total deviations:** 2. Both are no-tests-rule/verification-method substitutions (subtractive or additive-verification-only, pre-authorized by CLAUDE.md/STATE.md), not scope creep against the plan's production code. No architectural changes, no Rule 4 escalations.

## Issues Encountered
None beyond the two items documented above. `flutter build apk --debug` took ~263s on first Gradle invocation (cold Gradle daemon/dependency resolution); ran in the background and completed successfully (exit 0).

## Skipped (no-tests rule, not failures)
- `flutter test test/features/shell/bloc/shell_bloc_test.dart exits 0 with at least 8 tests` (Task 1) -- N/A, no automated tests in this project. Substituted: manual code trace of all 8 `<behavior>` cases (see above), all pass; `flutter analyze` clean.
- `flutter test test/features/shell/view/shell_page_test.dart exits 0 with 3 tests` / `flutter test test/architecture/layout_test.dart exits 0` / `flutter test` (whole suite) (Task 3) -- N/A, same reason. Substituted: grep/find architecture checks (all pass, see above) + a real Android-emulator boot with screenshot confirmation (see above) + `flutter analyze` (clean, whole project).
- All non-test grep/CLI acceptance criteria from all three tasks were run for real and passed: `sealed class ShellState extends Equatable` (1), `sealed class ShellEvent extends Equatable` (1), 8 accent hex literals, `useMaterial3: true` (1), `MyHomePage|_counter` in `lib/main.dart` (0), `MaterialApp.router` in `lib/app/app.dart` (3), `MultiRepositoryProvider` (2), `AppDatabase.open` in `lib/main.dart` (1), `get_it` in `pubspec.yaml` (0), `test -f test/widget_test.dart` (fails, file removed).

## User Setup Required
None - no external service configuration required. Android emulator (`emulator-5554`) and Android SDK platform-tools (`adb`) were already available in this environment and used only for throwaway verification (app uninstalled afterward).

## Next Phase Readiness
- `lib/app/app.dart` / `lib/app/dependencies.dart` / `lib/core/router/app_router.dart` are the standing composition root, DI and routing pattern Phase 2's feature Blocs and Phase 3's screens should extend (new routes appended to `AppRoutes`/`createAppRouter`, new repositories added to `AppDependencies`/`MultiRepositoryProvider`).
- `ShellPage`'s empty body is the mount point Phase 3 replaces with real content; `ShellBloc`'s theme/accent plumbing is ready for a future settings screen to dispatch `ShellThemeChanged`/`ShellAccentChanged` against.
- This was Phase 1's final plan (01-07 of 7). No blockers for Phase 2.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: lib/core/theme/accents.dart
- FOUND: lib/core/theme/app_theme.dart
- FOUND: lib/features/shell/data/theme_settings.dart
- FOUND: lib/features/shell/bloc/shell_event.dart
- FOUND: lib/features/shell/bloc/shell_state.dart
- FOUND: lib/features/shell/bloc/shell_bloc.dart
- FOUND: lib/core/router/app_router.dart
- FOUND: lib/features/shell/view/shell_page.dart
- FOUND: lib/app/dependencies.dart
- FOUND: lib/app/app.dart
- FOUND commit: 91b6642 (Task 1 commit)
- FOUND commit: 69d198a (Task 2 commit)
- FOUND commit: 68ec18d (Task 3 commit)
