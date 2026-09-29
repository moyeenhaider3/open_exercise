# UI-07 Translation Checklist: Zustand to BLoC & Native APIs

This document satisfies the **UI-07** requirement for Phase 3 ("BLoC & UI Translation"). It tracks every action in `useStore.js` and `useUI.js`, and every in-scope `update()` mutation closure from openGym (`../openGym/frontend/src/`) mapped to its Flutter BLoC event, native Flutter platform API, or deferred future phase.

---

## 1. `useStore.js` Actions

| Zustand Action | Scope / Phase | Flutter Equivalent | Notes |
|---|---|---|---|
| `update` | Phase 3 | `GymStateCubit.mutate` | Canonical single-writer state mutation primitive. Replaces inline JS state mutations. Push flag deferred to Phase 6. |
| `replaceState` | Phase 3 | `GymStateCubit.replaceState` | Full state replacement used for backup restore, reset, and demo seeds. |
| `autoBackupNow` | Phase 8 | Deferred (`IMP-04`) | Automatic file-mirror export after meaningful changes. |
| `isGuest` | Phase 5 | Deferred (`AUTH-05`) | Guest mode determination and flags. |
| `setGuest` | Phase 5 | Deferred (`AUTH-05`) | Toggling guest mode state. |
| `loadConfig` | Phase 5 / 6 | Deferred | Fetch server-side configuration from `/api/config`. |
| `refreshConfig` | Phase 5 / 6 | Deferred | Refresh cached server configuration. |
| `setUser` | Phase 5 | Deferred (`AUTH-04`) | Current signed-in user session management. |
| `pushState` | Phase 6 | Deferred (`SYNC-01`) | Synchronize local state mutations upstream to server. |
| `pullState` | Phase 6 | Deferred (`SYNC-01`) | Fetch latest server state mutations downstream. |
| `adoptProfile` | Phase 6 | Deferred (`SYNC-01`) | Profile merge upon signing in. |
| `signOut` | Phase 5 | Deferred (`AUTH-04`) | Terminate current user session locally. |
| `signOutAll` | Phase 5 | Deferred (`AUTH-04`) | Invalidate sessions across all active devices. |
| `chooseLocalMode` | Phase 5 | Deferred | Onboarding choice to remain local-only. |
| `connectToServer` | Phase 5 | Deferred (`AUTH-03`) | Pairing-code sign-in flow. |
| `disconnectServer` | Phase 5 | Deferred | Switch back to offline / local-only operation. |
| `resetDemo` | N/A | Not applicable | Web demo reset helper; no web demo build in Flutter. |
| `boot` | Phase 1 / 5 | `ShellBloc._onStarted` | Initial database hydration completed in Phase 1; server ping / guest branching deferred to Phase 5. |
| `setCoachLocal` | Phase 7 | Deferred | Local AI coach device settings and preferences. |

---

## 2. `useUI.js` Actions

| Zustand Action | Scope / Phase | Flutter Equivalent | Notes |
|---|---|---|---|
| `openSheet` | Phase 3 | `showAppSheet` / `showCenterDialog` | Native modal bottom sheet and center dialog presentation (Pattern 3 / D-05). |
| `closeSheet` | Phase 3 | `Navigator.pop` | Native Flutter navigation stack dismissal. |
| `closeAll` | Phase 3 | `closeAllSheets` / `Navigator.popUntil` | Closes modal routes back to root route. |
| `toast` | Phase 3 | `showToast` | Transient toast notification banner (2200ms fixed overlay). |
| `flashTimer` | Phase 5 | Deferred (`TMR-01`) | Screen-flash visual alert upon timer expiry. |
| `startRest` | Phase 5 | Deferred (`TMR-01`) | Rest timer countdown initiation between sets (D-02). |
| `addRest` | Phase 5 | Deferred (`TMR-01`) | Increment active rest timer duration. |
| `shiftRestOwner` | Phase 5 | Deferred (`TMR-01`) | Transfer rest timer ownership on unit/set change. |
| `stopRest` | Phase 5 | Deferred (`TMR-01`) | Cancel / dismiss active rest timer. |
| `startWork` | Phase 5 | Deferred (`TMR-01`) | Timed-set work hold countdown initiation (D-02). |
| `finishWorkEarly` | Phase 5 | Deferred (`TMR-01`) | Early completion of timed set work countdown. |
| `stopWork` | Phase 5 | Deferred (`TMR-01`) | Cancel / abort timed set work countdown. |

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

---

## 4. Deferred Surfaces & Technical Boundaries

The following UI surfaces and integrations identified during porting are explicitly deferred to future phases:

| Feature / UI Surface | Target Phase | Rationale |
|---|---|---|
| Plan Tools (Share / Print / Import) | Phase 8 (`IMP-04`) | Requires platform printing, system sharing, and document picking packages. |
| Library "By Muscle" & Picker Muscle Toggle | Phase 4 (`VIS-01`) | Depends on `BodyMap` SVG anatomy renderer. |
| RoutineEdit "What this session hits" | Phase 4 (`VIS-02`) | Interactive anatomy visualization widget. |
| FinishSummary "What you just trained" | Phase 4 (`VIS-02`) | Post-workout muscle volume breakdown visualizer. |
| AI Coach CTA in Plan | Phase 7 (`COACH-01`) | LLM prompt orchestration and recommendations. |
| Activity Heartbeat / Presence Ping | Phase 6 / 7 | Live server presence and background sync telemetry. |
| Rest & Work Timers (beeps, vibrate, audio cues) | Phase 5 (`TMR-01`) | Audio playback and haptics infrastructure (D-02). |
| Automatic File Backup on Session Finish | Phase 8 (`IMP-04`) | Platform storage file mirroring. |
| Backfill / Log Past Workout & Day Override | Phase 3.1 (Home) | Home screen retro-logging calendar entrypoints. |
| TopWeight Manual Override | N/A | Unreachable code path in openGym web; omitted. |

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
grep -oE "\`[A-Z][A-Za-z]+(Requested|Changed|Toggled|Added|Removed|Moved|Saved|Deleted|Confirmed|Discarded|Renamed|Focused|Navigated|Paired|Unpaired|Swapped|Picked|Configured|Bumped|Loaded|Assigned|Copied|Reordered|Selected|Linked)\`" .planning/phases/03-bloc-ui-translation/03-UI07-CHECKLIST.md | tr -d '\`' | sort -u | while read e; do
  grep -rq "final class $e\b" lib || echo "NO CLASS $e"
done
```
