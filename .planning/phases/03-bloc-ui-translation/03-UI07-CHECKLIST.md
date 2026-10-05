# UI-07 Translation Checklist: Zustand to BLoC & Native APIs

This document satisfies the **UI-07** requirement for Phase 3 ("BLoC & UI Translation") and Phase 3.1 ("History, Stats, Home, Check-in & Settings"). It tracks every action in `useStore.js` and `useUI.js`, and every in-scope `update()` mutation closure from openGym (`../openGym/frontend/src/`) mapped to its Flutter BLoC event, native Flutter platform API, or deferred future phase.

---

## 1. `useStore.js` Actions

| Zustand Action | Scope / Phase | Flutter Equivalent | Notes |
|---|---|---|---|
| `update` | Phase 3 | `GymStateCubit.mutate` | Canonical single-writer state mutation primitive. Replaces inline JS state mutations. Push flag deferred to Phase 6. |
| `replaceState` | Phase 3 | `GymStateCubit.replaceState` | Full state replacement used for backup restore, reset, and demo seeds. |
| `autoBackupNow` | Phase 8 | Deferred (`IMP-04`) | Automatic file-mirror export after meaningful changes. |
| `isGuest` | Phase 5 | N/A (guest-only, Phase 5 D-01) | Always guest; openGym lib/guest.js guestAllowed(null) === true with no server config (D-03). |
| `setGuest` | Phase 5 | N/A (guest-only, Phase 5 D-01) | Always guest; openGym lib/guest.js guestAllowed(null) === true with no server config (D-03). |
| `loadConfig` | Phase 5 | N/A (guest-only, Phase 5 D-01) | No server; guest config is null (D-03). |
| `refreshConfig` | Phase 5 | N/A (guest-only, Phase 5 D-01) | No server; guest config is null (D-03). |
| `setUser` | Phase 5 | N/A (guest-only, Phase 5 D-01) | No user session; runs as guest only (D-01). |
| `pushState` | Phase 6 | N/A (online sync out of scope, BAK-01) | Online sync out of scope for v1 (REQUIREMENTS.md, 2026-09-30); Phase 6 is local backup. |
| `pullState` | Phase 6 | N/A (online sync out of scope, BAK-01) | Online sync out of scope for v1 (REQUIREMENTS.md, 2026-09-30); Phase 6 is local backup. |
| `adoptProfile` | Phase 6 | N/A (online sync out of scope, BAK-01) | Online sync out of scope for v1 (REQUIREMENTS.md, 2026-09-30); Phase 6 is local backup. |
| `signOut` | Phase 5 | N/A (guest-only, Phase 5 D-01) | No user session to sign out of (D-01). |
| `signOutAll` | Phase 5 | N/A (guest-only, Phase 5 D-01) | No user session to sign out of (D-01). |
| `chooseLocalMode` | Phase 5 | N/A (guest-only, Phase 5 D-01) | The app is always local-only; no mode choice screen needed (D-01). |
| `connectToServer` | Phase 5 | N/A (guest-only, Phase 5 D-01) | Server pairing/connection UI is out of scope for v1 (D-01). |
| `disconnectServer` | Phase 5 | N/A (guest-only, Phase 5 D-01) | Server pairing/connection UI is out of scope for v1 (D-01). |
| `resetDemo` | N/A | Not applicable | Web demo reset helper; no web demo build in Flutter. |
| `boot` | Phase 1 / 5 | `ShellBloc._onStarted` | Initial database hydration completed in Phase 1; server ping / guest branching N/A (guest-only). |
| `setCoachLocal` | Phase 7 | Deferred | Local AI coach device settings and preferences. |

---

## 2. `useUI.js` Actions

| Zustand Action | Scope / Phase | Flutter Equivalent | Notes |
|---|---|---|---|
| `openSheet` | Phase 3 | `showAppSheet` / `showCenterDialog` | Native modal bottom sheet and center dialog presentation (Pattern 3 / D-05). |
| `closeSheet` | Phase 3 | `Navigator.pop` | Native Flutter navigation stack dismissal. |
| `closeAll` | Phase 3 | `closeAllSheets` / `Navigator.popUntil` | Closes modal routes back to root route. |
| `toast` | Phase 3 | `showToast` | Transient toast notification banner (2200ms fixed overlay). |
| `flashTimer` | Phase 5 | WorkoutTimerBloc flashId (`TimerFlash`) | Screen-flash visual alert upon timer expiry (`WorkoutTimerState.flashId`). |
| `startRest` | Phase 5 | `WorkoutRestStarted` | Rest timer countdown initiation between sets (D-02). |
| `addRest` | Phase 5 | `WorkoutRestAdded` | Increment active rest timer duration (+15s / -15s). |
| `shiftRestOwner` | Phase 5 | `WorkoutRestOwnerShifted` | Transfer rest timer ownership on unit/set change (+ `WorkoutRestOwnerRemapped`, `WorkoutRestExerciseRemoved`). |
| `stopRest` | Phase 5 | `WorkoutRestStopped` | Cancel / dismiss active rest timer. |
| `startWork` | Phase 5 | `WorkoutWorkStarted` | Timed-set work hold countdown initiation (via `WorkoutTimedSetStarted`). |
| `finishWorkEarly` | Phase 5 | `WorkoutWorkFinishedEarly` | Early completion of timed set work countdown. |
| `stopWork` | Phase 5 | `WorkoutWorkStopped` | Cancel / abort timed set work countdown. |

---

## 3. In-Scope `update()` Closures & Screen Features

### Library & Exercise Management (`views/Library.jsx`, `components/Media.jsx`, `sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Library.jsx:32` | Toggle exercise favourite | `ExerciseFavouriteToggled` |
| `views/Library.jsx:45` | Query text filter changed | `LibraryQueryChanged` |
| `views/Library.jsx:52` | Body part filter selected | `LibraryBodyPartSelected` |
| `views/Library.jsx:61` | Equipment filter selected | `LibraryEquipmentSelected` |
| `views/Library.jsx:75` | Show all / show hidden toggle | `LibraryShowAllToggled` |
| `views/Library.jsx:82` | Show more items in pagination | `LibraryShowMoreRequested` |
| `components/Media.jsx:30` | Toggle media thumbnail / expand | `MediaSizeToggled` |
| `sheets.jsx:130` | Save custom exercise definition | `CustomExerciseSaved` |
| `sheets.jsx:155` | Request custom exercise deletion | `CustomExerciseDeleteRequested` |
| `sheets.jsx:162` | Confirm custom exercise deletion | `CustomExerciseDeleted` |
| `sheets.jsx:210` | Add library exercise to routine | `ExerciseAddedToRoutine` |
| `sheets.jsx:240` | Change barbell base weight | `ExerciseBarWeightChanged` |
| `sheets.jsx:255` | Toggle bodyweight / no bar flag | `ExerciseNoBarChanged` |
| `views/Library.jsx:39`, `views/Muscles.jsx:1-20`, `components/MuscleExplorer.jsx:1-110` | Explore muscles view, muscle selection, filtering and search | `MusclesBloc` (`MusclesQueryChanged`, `MusclesBodyPartSelected`, `MusclesEquipmentSelected`, `MusclesShowAllToggled`, `MusclesShowMoreRequested`, `muscle_explorer.dart`, `muscles_screen.dart`, route `/muscles`) |
| `sheets.jsx:941-951` | Toggle By muscle mode in exercise picker | `ExercisePickerCubit.byMuscleChanged` (hosts `MuscleExplorer` in `exercise_picker_sheet.dart`) |

### Plan & Routine Configuration (`views/Plan.jsx`, `views/RoutineEdit.jsx`, `sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Plan.jsx:40` | Add new routine | `PlanRoutineAdded` |
| `views/Plan.jsx:55` | Reorder routines list | `PlanRoutineMoved` |
| `views/Plan.jsx:70` | Assign routine to day of week | `PlanDayAssigned` |
| `views/Plan.jsx:85` | Add additional routine to day | `PlanDayRoutineAdded` |
| `views/Plan.jsx:92` | Remove routine from day | `PlanDayRoutineRemoved` |
| `views/Plan.jsx:105` | Request starter PPL plan load | `PlanStarterLoadRequested` |
| `views/Plan.jsx:112` | Confirm starter plan loaded | `PlanStarterLoaded` |
| `views/RoutineEdit.jsx:80` | Rename routine | `RoutineRenamed` |
| `views/RoutineEdit.jsx:95` | Change routine glyph / icon | `RoutineGlyphChanged` |
| `views/RoutineEdit.jsx:110`| Change routine progression policy | `RoutineProgressionPolicyChanged` |
| `views/RoutineEdit.jsx:125`| Toggle routine exclude-from-stats | `RoutineExcludeChanged` |
| `views/RoutineEdit.jsx:150`| Add exercise to routine | `RoutineExerciseAdded` |
| `views/RoutineEdit.jsx:180`| Configure routine exercise target | `RoutineExerciseConfigured` |
| `views/RoutineEdit.jsx:210`| Remove exercise from routine | `RoutineExerciseRemoved` |
| `views/RoutineEdit.jsx:240`| Move exercise unit up / down | `RoutineUnitMoved` |
| `views/RoutineEdit.jsx:265`| Drag reorder exercise unit | `RoutineUnitReordered` |
| `views/RoutineEdit.jsx:290`| Toggle superset link between items | `RoutineLinkToggled` |
| `views/RoutineEdit.jsx:320`| Copy routine | `RoutineCopied` |
| `views/RoutineEdit.jsx:340`| Delete routine | `RoutineDeleted` |
| `views/RoutineEdit.jsx:418-429` | Anatomy hit map and worked muscles for routine | `BodyMap` with `loadOfRoutine` in `routine_edit_screen.dart` |

### Active Workout Session (`views/Workout.jsx`, `sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Workout.jsx:45` | Start workout session | `WorkoutStartRequested` |
| `views/Workout.jsx:68` | Discard active session | `WorkoutDiscarded` |
| `views/Workout.jsx:90` | Request finish confirmation | `WorkoutFinishRequested` |
| `views/Workout.jsx:110`| Confirm finish early / anyway | `WorkoutFinishConfirmed` |
| `views/Workout.jsx:135`| Rename active workout | `WorkoutRenamed` |
| `views/Workout.jsx:150`| Update workout session note | `WorkoutSessionNoteChanged` |
| `views/Workout.jsx:175`| Update exercise note | `WorkoutExerciseNoteSaved` |
| `views/Workout.jsx:210`| Change layout (cards/list/compact)| `WorkoutViewChanged` |
| `views/Workout.jsx:230`| Focus / set current exercise unit | `WorkoutUnitFocused` |
| `views/Workout.jsx:250`| Navigate cards prev / next | `WorkoutUnitNavigated` |
| `views/Workout.jsx:280`| Move workout unit up / down | `WorkoutUnitMoved` |
| `views/Workout.jsx:310`| Pair consecutive units into superset | `WorkoutPaired` |
| `views/Workout.jsx:330`| Unpair superset into single units | `WorkoutUnpaired` |
| `views/Workout.jsx:360`| Add exercise to active session | `WorkoutExerciseAdded` |
| `views/Workout.jsx:390`| Swap active exercise with another | `WorkoutExerciseSwapped` |
| `views/Workout.jsx:420`| Remove exercise from session | `WorkoutExerciseRemoved` |
| `views/Workout.jsx:450`| Add routine exercises to session | `WorkoutRoutineAddedToSession` |
| `views/Workout.jsx:510`| Change set weight / reps / time | `WorkoutSetFieldChanged` |
| `views/Workout.jsx:530`| Stepper bump set weight / reps | `WorkoutSetFieldBumped` |
| `views/Workout.jsx:550`| Add straight set to exercise | `WorkoutSetAdded` |
| `views/Workout.jsx:565`| Remove set from exercise | `WorkoutSetRemoved` |
| `views/Workout.jsx:580`| Remove specific set index | `WorkoutSetRemovedAt` |
| `views/Workout.jsx:600`| Add warm-up set | `WorkoutWarmupAdded` |
| `views/Workout.jsx:620`| Add drop set to target set | `WorkoutDropAdded` |
| `views/Workout.jsx:635`| Remove drop set from target set | `WorkoutDropRemoved` |
| `views/Workout.jsx:650`| Change drop set field | `WorkoutDropFieldChanged` |
| `views/Workout.jsx:665`| Bump drop set field with steppers | `WorkoutDropFieldBumped` |
| `views/Workout.jsx:680`| Add rest-pause burst | `WorkoutBurstAdded` |
| `views/Workout.jsx:695`| Remove rest-pause burst | `WorkoutBurstRemoved` |
| `views/Workout.jsx:710`| Change rest-pause burst field | `WorkoutBurstFieldChanged` |
| `views/Workout.jsx:725`| Bump burst field with steppers | `WorkoutBurstFieldBumped` |
| `views/Workout.jsx:750`| Change unilateral per-side field | `WorkoutSideFieldChanged` |
| `views/Workout.jsx:780`| Toggle set done checkbox | `WorkoutSetToggled` |
| `views/Workout.jsx:810`| Pick RPE / RIR effort rating | `WorkoutEffortPicked` |
| `views/Workout.jsx:840`| Save progression configuration | `WorkoutProgressionConfigured` |
| `views/Workout.jsx` / lifecycle | App background / foreground timer sync | `WorkoutTimerAppHidden`, `WorkoutTimerAppShown` |
| `views/Workout.jsx` | Timed set logged from hold timer completion | `WorkoutTimedSetLogged` |

### History & Workout Detail (`views/History.jsx`, `sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `sheets.jsx:1674` | Save session note on blur | `HistoryWorkoutNoteSaved` |
| `sheets.jsx:1690` | Flush session note on sheet unmount | `HistoryWorkoutNoteSaved` |
| `sheets.jsx:1739` | Delete workout from history with confirm | `HistoryWorkoutDeleted` |
| `views/History.jsx:14` | Tap "Log a past workout" button | `WorkoutBackfillStarted` |
| `sheets.jsx:1846` | Save past workout form in backfill sheet | `WorkoutBackfillStarted` |
| `sheets.jsx:2188` | Complete past session finish branch | `WorkoutFinishConfirmed` via `FinishResult.past` |
| `sheets.jsx:2173-2174` | Post-workout muscle volume breakdown anatomy map | `BodyMap` with `loadOfWorkouts` in `finish_flow.dart` |

### Calendar & Day Override (`sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `sheets.jsx:1603` | Assign routine, rest, or reset override | `PlanDayOverrideSet` |
| `sheets.jsx:1772,1774` | Calendar previous / next month navigation | Screen-local `State` |

### Home Dashboard (`views/Home.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Home.jsx:71,73` | Prev/next week navigation buttons | `HomeWeekOffsetChanged` |
| `views/Home.jsx:61,81` | Tap today session card | `WorkoutStartRequested` via `startFlow` / `go('/workout')` / `showDayOverrideSheet` |

### Body Weight & Goal Tracking (`sheets.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `sheets.jsx:208` | Save bodyweight entry in BwSheet | `BodyweightLogged` |
| `sheets.jsx:218` | Delete bodyweight weigh-in history row | `BodyweightEntryDeleted` |
| `sheets.jsx:568` | Save target body weight goal | `BodyweightGoalSet` |
| `sheets.jsx:571` | Remove target body weight goal | `BodyweightGoalRemoved` |

### Stats & Analytics (`views/Stats.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Stats.jsx:252` | Switch effort distribution window (7d/30d/90d/1y/all) | `StatsEffortWindowChanged` |
| `views/Stats.jsx:465` | Switch stats charts time range | `StatsRangeChanged` |
| `views/Stats.jsx:474` | Select exercise for progress analytics | `StatsExerciseSelected` |
| `views/Stats.jsx:483` | Select exercise metric tab (top/e1rm/effort) | `StatsExerciseMetricChanged` |
| `views/Stats.jsx:100-232` | Muscle balance, fatigue, and strength map views | `MuscleBalanceBloc` (`MuscleBalanceViewChanged`, `MuscleBalanceWindowChanged`, `MuscleBalanceHardToggled`, `muscle_balance_card.dart`) |

### Check-in Rail & Gym Cards (`views/CheckIn.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/CheckIn.jsx:68` | Settle on card during carousel scroll | `CheckInActiveCardChanged` |
| `views/CheckIn.jsx:122` | Move card left or right in rail | `CheckInCardMoved` |
| `views/CheckIn.jsx:117` | Remove gym card after confirmation | `CheckInCardRemoved` |
| `views/CheckIn.jsx:168` | Rename gym card in CardSheet | `CheckInCardRenamed` |

### Settings & App Configuration (`views/Settings.jsx`, `sheets.jsx`, `App.jsx`)

| Source Location | Trigger / Action | Flutter BLoC Event / Native API |
|---|---|---|
| `views/Settings.jsx:44` | Switch weight unit (kg/lb) with conversion choice | `SettingsUnitSwitched` |
| `views/Settings.jsx:254,261,266` | Change wdec, weekStart, or gym checkIn visibility | `SettingsGeneralChanged` |
| `views/Settings.jsx:276,286,294,300,306,316,321,329,333,341` | Change weighIn, workoutView, restSec, restPauseSec, keepAwake, gifSize, sound, soundOnSilent, timerFlash, effort | `SettingsWorkoutChanged` |
| `views/Settings.jsx:462` | Toggle workout controls in WorkoutControlsSheet | `SettingsWorkoutControlsChanged` |
| `views/Settings.jsx:361` | Switch app theme (dark/light/system) | `ShellThemeChanged` |
| `views/Settings.jsx:370` | Switch body anatomy preference (male/female) | `SettingsBodyChanged` |
| `views/Settings.jsx:378` | Select UI accent color swatch | `ShellAccentChanged` |
| `views/Settings.jsx:647` | Toggle equipment filter on/off | `SettingsEquipFilterToggled` |
| `views/Settings.jsx:650` | Select active equipment profile | `SettingsActiveEquipChanged` |
| `sheets.jsx:1084` | Save profile in EquipmentProfileSheet | `SettingsEquipProfileSaved` |
| `views/Settings.jsx:640` | Delete equipment profile with confirmation | `SettingsEquipProfileDeleted` |
| `views/Settings.jsx:316,333` | Change keepAwake or soundOnSilent | `SettingsWorkoutChanged` |
| `components/MobileReminderCard.jsx:1-120` | Toggle workout-day reminder or change time | `SettingsReminderToggled`, `SettingsReminderTimeChanged` |
| `views/Settings.jsx:345` | Request rest-timer notification permissions or status | `SettingsRestAlertsRequested`, `SettingsNotificationStatusRequested` |
| `views/Settings.jsx:173` | Confirm reset all data and state | `SettingsResetConfirmed` |
| `App.jsx:85` | React to wdec changes to configure weight formatters | `BlocListener` in `app.dart` |

---

## 4. Deferred Surfaces & Technical Boundaries

The following UI surfaces and integrations identified during porting are explicitly deferred to future phases:

| Feature / UI Surface | Target Phase | Rationale |
|---|---|---|
| Plan Tools (Share / Print / Import) | Phase 8 (`IMP-04`) | Requires platform printing, system sharing, and document picking packages. |
| AI Coach | Phase 7 (`COACH-01`) | LLM prompt orchestration, AI chat, and coach recommendations. |
| Activity Heartbeat / Presence Ping | Phase 6 / 7 | Live server presence and background sync telemetry. |
| Rest & Work Timers (beeps, vibrate, audio cues) | Phase 5 (`TMR-01`) | Done in Phase 5: `WorkoutTimerBloc`, audio tone player, and haptics infrastructure. |
| Automatic File Backup on Session Finish | Phase 8 (`IMP-04`) | Platform storage file mirroring (`autoBackupNow`). |
| Backfill / Log Past Workout & Day Override | Phase 3.1 | Done in Phase 3.1 (`WorkoutBackfillStarted`, `PlanDayOverrideSet`). |
| TopWeight Manual Override | N/A | Unreachable code path in openGym web; omitted. |
| Check-in Add card + Re-scan / Import photo | Phase 8 (`IMP-03`, `D-03`) | Native camera QR scanner and image decoding. |
| Settings Language | Phase 8 | Localization selector hidden until multi-language translations ready. |
| Import backup / Export backup / Auto-backup | Phase 8 (`IMP-04`) | File import picker, share export, and periodic backup. |
| Import from another app / Hevy | Phase 8 (`IMP-01`) | External workout tracker backup parsers (Hevy, Strong, FitNotes). |
| Notifications / workout-day reminder | Phase 5 (`TMR-03`) | Done in Phase 5: `NotificationService` local notifications on planned workout days. |
| Keep screen awake + Play sounds on silent rows, rest-timer/sound/flash behaviour | Phase 5 (`TMR-01`) | Done in Phase 5: `WakelockPlus`, audio session category, and screen flash overlay. |
| Account / pairing / passkey rows | N/A (guest-only, D-01) | User profile, WebAuthn passkey authentication, server sync pairing out of scope for v1. |
| Tip (Add to Home screen) and Updates (APK updater) | N/A | Web PWA install banner and APK downloader not applicable to native store app. |
| Home 'Hi {name}' greeting | N/A (guest-only, D-01) | In guest mode without an account, user name is not present. |

---

## 5. How to Verify

Run these automated verification loops to confirm complete coverage:

### Check all `useStore.js` and `useUI.js` actions are listed:
```bash
for a in update replaceState autoBackupNow isGuest setGuest loadConfig refreshConfig setUser pushState pullState adoptProfile signOut signOutAll chooseLocalMode connectToServer disconnectServer resetDemo boot setCoachLocal openSheet closeSheet closeAll toast flashTimer startRest addRest shiftRestOwner stopRest startWork finishWorkEarly stopWork; do
  grep -q "\`$a\`" .planning/phases/03-bloc-ui-translation/03-UI07-CHECKLIST.md || echo "MISSING $a"
done
```

### Check all named BLoC event classes exist in the Dart codebase:
```bash
grep -oE "\`[A-Z][A-Za-z]+(Requested|Changed|Toggled|Added|Removed|Moved|Saved|Deleted|Confirmed|Discarded|Renamed|Focused|Navigated|Paired|Unpaired|Swapped|Picked|Configured|Bumped|Loaded|Assigned|Copied|Reordered|Selected|Linked|Started|Set|Logged|Switched)\`" .planning/phases/03-bloc-ui-translation/03-UI07-CHECKLIST.md | tr -d '\`' | sort -u | while read e; do
  grep -rq "final class $e\b" lib || echo "NO CLASS $e"
done
```

### Check all Phase 3.1 BLoC event classes exist in the Dart codebase:
```bash
for e in WorkoutBackfillStarted PlanDayOverrideSet HistoryWorkoutNoteSaved HistoryWorkoutDeleted BodyweightLogged BodyweightEntryDeleted BodyweightGoalSet BodyweightGoalRemoved HomeWeekOffsetChanged StatsRangeChanged StatsExerciseSelected StatsExerciseMetricChanged StatsEffortWindowChanged CheckInCardMoved CheckInCardRenamed CheckInCardRemoved CheckInActiveCardChanged SettingsUnitSwitched SettingsGeneralChanged SettingsWorkoutChanged SettingsWorkoutControlsChanged SettingsBodyChanged SettingsEquipFilterToggled SettingsActiveEquipChanged SettingsEquipProfileSaved SettingsEquipProfileDeleted SettingsResetConfirmed ShellThemeChanged ShellAccentChanged WorkoutStartRequested WorkoutFinishConfirmed; do
  grep -rq "final class $e\b" lib || echo "MISSING 3.1 EVENT $e"
done
```

### Check all Phase 5 BLoC event classes exist in the Dart codebase:
```bash
for e in WorkoutRestStarted WorkoutRestAdded WorkoutRestOwnerShifted WorkoutRestOwnerRemapped WorkoutRestExerciseRemoved WorkoutRestStopped WorkoutWorkStarted WorkoutWorkFinishedEarly WorkoutWorkStopped WorkoutTimerAppHidden WorkoutTimerAppShown WorkoutTimedSetStarted WorkoutTimedSetLogged SettingsReminderToggled SettingsReminderTimeChanged SettingsRestAlertsRequested SettingsNotificationStatusRequested; do
  grep -rq "final class $e\b" lib || echo "MISSING 5 EVENT $e"
done
```

---

## 6. UI-08 Audit (Phase 3 + 3.1)

Commands and results verifying architecture and list virtualization rules:

| Gate | Command | Result |
|---|---|---|
| No unbounded raw lists | `grep -rnE "ListView\(|GridView\(|GridView\.count\(" lib/features lib/core/ui_kit` | PASS (0 occurrences; builders/slivers used, bounded Settings/Plan use Column) |
| Views do not mutate state directly | `grep -rn "\.mutate(\|\.replaceState(" lib/features/*/view` | PASS (0 occurrences) |
| Single writer persistence pattern (D-04) | `grep -rn "saveState(\|importState(" lib --include=*.dart \| grep -v "lib/core/data/\|lib/core/state/"` | PASS (0 occurrences outside repository/state layers) |
| AGPL-3.0 License headers | `grep -rn "SPDX-License-Identifier: AGPL-3.0-or-later" -L lib/features lib/core --include=*.dart \| grep -v "/generated/\|\.g\.dart"` | PASS (All hand-written files contain header) |
| Clean static analysis | `flutter analyze` | PASS (No issues found!) |
| JS-04 architecture audit | `bash tool/js04_audit.sh` | PASS (exit 0) |
| No test files or forbidden deps | `git ls-files --others --cached \| grep -E "(^\|/)(test\|integration_test\|test_driver)/\|_test\.dart$"` & `grep -nE "bloc_test\|mocktail\|sqflite_common_ffi" pubspec.yaml` | PASS (No test artifacts or dependencies) |
