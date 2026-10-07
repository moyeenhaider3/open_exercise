# Roadmap: open_exercise (openGym → Flutter)

## Overview

Port openGym to native Flutter in horizontal layers. Build the data foundation first, then the original JS logic running in QuickJS, then the UI on top of both. Muscle map, timers/auth, sync and the extended features (Coach, Admin, Import/Share, i18n) follow. Each phase waits for user approval before the next one starts.

## Phases

- [x] **Phase 1: Foundation & Models** - Folder structure, OpenAPI models + Dio clients, state models, sqflite schema (completed 2026-09-25)
- [x] **Phase 2: Core Logic via QuickJS** - Bundle openGym lib JS, JsEngineService, parity script
- [x] **Phase 3: BLoC & UI Translation** - State layer, Library, exercise detail, workout tracker, plan/routines in Material 3
- [ ] **Phase 3.1: History, Stats, Home, Check-in & Settings** (INSERTED) - Remaining screens on the Phase 3 state layer
- [ ] **Phase 4: Muscle Map Rendering** - SVG paths → CustomPainter with fatigue/volume shading
- [ ] **Phase 5: Timers & Guest Mode** - Background rest alerts, reminders, guest-only (no account, no server)
- [ ] **Phase 6: Local Backup & Restore** - Periodic JSON backups to a user-chosen device folder, manual backup, full restore from file
- [ ] **Phase 7: Coach & Admin** - AI Coach flows and admin panel
- [ ] **Phase 8: Import, Share & i18n** - Hevy/CSV import, QR/barcode, 14 locales

## Phase Details

### Phase 1: Foundation & Models

**Goal**: A typed, persisted data layer that can hold a real openGym state file and talk to every API route
**Depends on**: Nothing (first phase)
**Requirements**: FND-01, FND-02, FND-03, FND-04, FND-05
**Success Criteria** (what must be TRUE):

  1. `lib/core/` and `lib/features/` exist, and the app boots to an empty themed shell
  2. Generated Dart models + Dio clients compile and cover every path in `openapi.yaml`
  3. A representative (synthetic, demoSeed-derived) `state-<uid>.json` imports into sqflite and exports back to equivalent JSON (verified by a throwaway round-trip script; no tests per project rule, user-accepted 2026-09-25). Note: user accepted the synthetic fixture on 2026-09-25 (no real file available)
  4. `flutter analyze` passes (no tests per project rule, user-accepted 2026-09-25)

**Plans**: 7 plans

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Gate + install core deps, AGPL license/NOTICE, strict analyzer (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — OpenAPI generator spike + user decision (wave 2)
- [x] 01-03-PLAN.md — Synthetic state fixture, JsonReader passthrough, Workout/SetEntry models (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — Routine/bodyweight/part models, kDefaultState, GymState (wave 3)
- [x] 01-05-PLAN.md — Generate Dio clients from openapi.yaml, 30-operation coverage test (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-06-PLAN.md — sqflite hybrid schema, GymStateRepository, round-trip test (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 01-07-PLAN.md — Theme/accents, sealed ShellBloc, go_router, DI, boot + layout tests (wave 5)

### Phase 2: Core Logic via QuickJS

**Goal**: openGym's domain math runs unchanged inside the app and gives identical results
**Depends on**: Phase 1
**Requirements**: JS-01, JS-02, JS-03, JS-04
**Success Criteria** (what must be TRUE):

  1. One script rebuilds the JS bundle asset from `../openGym/frontend/src/lib/`
  2. `JsEngineService` returns 1RM, progression, plate and recovery results as Dart models
  3. The parity script (`tool/`, not a test) matches openGym's vitest fixtures exactly

**Plans:** 8 plans

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Vendor openGym lib modules (SHA-256 manifest) + pinned esbuild IIFE bundle via tool/gen_js_bundle.sh (JS-01)
- [x] 02-02-PLAN.md — Add flutter_js, verify its real API, headless probe, Android/iOS build probes, CocoaPods decision checkpoint

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-03-PLAN.md — JsEngineService (safe JSON call protocol, strict codec), app DI wiring, engine smoke on QuickJS + JavaScriptCore
- [x] 02-04-PLAN.md — Plain-Node parity oracle: bridge inventory, vitest-cross-checked, TZ-deterministic fixtures embedded for the harness

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-05-PLAN.md — onerm/bar/workout-model typed facades + dispatch; remove SetEntry hand-port (CR-02); tool/js04_audit.sh (JS-04)
- [x] 02-06-PLAN.md — progression + recovery typed facades + dispatch
- [x] 02-07-PLAN.md — history + session start/merge typed facades + dispatch

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 02-08-PLAN.md — Device-run parity harness + tool/run_parity.sh; PASS on Android (QuickJS) and iOS (JavaScriptCore); final JS-04 + reproducibility gates

### Phase 3: BLoC & UI Translation

**Goal**: A user can browse exercises and run a full workout offline, with screens that match openGym
**Depends on**: Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-07 (Phase 3 screens), UI-08 (Phase 3 screens)
**Success Criteria** (what must be TRUE):

  1. User can find an exercise, start a workout, log straight/warm-up/drop/rest-pause sets and finish it, all offline
  2. Progression suggestions shown in the UI match openGym for the same history
  3. Plan and RoutineEdit screens work (drag to reorder), and data persists across restarts
  4. Every in-scope Zustand action maps to a Bloc event (checklist in the phase summary)

**Plans**: 16 plans in 5 waves

Plans:
**Wave 1**

- [x] 03-01-PLAN.md — State layer: single-writer GymStateCubit (D-04), model copyWith/extras, S.week lists, ShellBloc on the cubit, provider files
- [x] 03-02-PLAN.md — JS bridge additions: exercises, muscles, effort, starter, exerciseHistory, repRange, progressionCopy, finish shim + parity
- [x] 03-03-PLAN.md — Presentation foundation: path_drawing AppIcon (generated from Icon.jsx), t(), format.js/glyphs/workout-controls ports, setLabel/exLine

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-04-PLAN.md — ui_kit: ui.jsx controls, AppPalette, native sheet/dialog/toast helpers (D-05)
- [x] 03-05-PLAN.md — Exercise catalogue (generated), typo-tolerant search port, favourites/equipment, LibraryBloc + ExercisesBloc, registerCustom
- [x] 03-06-PLAN.md — App shell: go_router route table + TabBar.jsx port
- [x] 03-07-PLAN.md — WorkoutBloc lifecycle/session events + supersetFlow/order/swap ports (no timers, D-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-08-PLAN.md — ExConfig + ProgressionFields, glyph picker, AddToRoutine, BarWeightEditor sheets
- [x] 03-09-PLAN.md — Exercise media (CDN + ImageCache), custom exercise form/delete, exercise picker
- [x] 03-10-PLAN.md — WorkoutBloc set editing, tick/superset flow, progression reconfigure, WorkoutEntryView
- [x] 03-11-PLAN.md — PlanBloc + Plan screen + day/starter sheets
- [x] 03-12-PLAN.md — Workout session sheets: weigh-in, effort picker, notes, rename, add routine, remove/swap, finish flow

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 03-13-PLAN.md — Exercise detail + history (LineChart) + Library screen [device check]
- [x] 03-14-PLAN.md — RoutineEdit (ReorderableListView, Dismissible) [device check incl. restart persistence]
- [x] 03-15-PLAN.md — ExerciseBlock + set rows (all set types)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 03-16-PLAN.md — Start chooser, ActiveWorkout (cards/list/compact), tab Start, UI-07 checklist [device check]

**UI hint**: yes

### Phase 03.1: History, Stats, Home, Check-in & Settings (INSERTED)

**Goal**: The remaining openGym screens (History, Stats, Home, Check-in, Settings) work offline on the Phase 3 state layer and match openGym
**Depends on**: Phase 3
**Requirements**: UI-05, UI-06, UI-07 (remaining screens), UI-08 (remaining screens)
**Success Criteria** (what must be TRUE):

  1. History and Stats show charts, heatmap, 1RM trends and bodyweight (Stats muscle-balance card deferred to Phase 4)
  2. Home, Check-in (display/reorder/edit/delete; Add card deferred to Phase 8) and Settings match openGym's options
  3. Settings changes persist across restarts
  4. The UI-07 Zustand-to-Bloc checklist is complete across Phase 3 + 3.1

**Plans**: 13 plans in 5 waves

Plans:
**Wave 1**

- [x] 03.1-01-PLAN.md — Vendor backfill.js + units.js, finish-shim backfill branch, BackfillJs/UnitsJs facades + fixtures + parity
- [x] 03.1-02-PLAN.md — Device recheck of the "Volume (0 kg)" finish summary; fix WorkoutBloc if it is a real bug [device check]
- [x] 03.1-03-PLAN.md — Routes (/history, /settings, /checkin), provider files, setWeightDecimals wiring, WorkoutRowTile, Heatmap widget

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03.1-04-PLAN.md — EffortJs extensions + viewAgg shim / ViewAggregatesJs facade (stats, heatmap, calendar, Home summary) + parity
- [x] 03.1-05-PLAN.md — Log a past workout: WorkoutBackfillStarted, completeBackfill finish branch, LogPastWorkout/SameDayChoice sheets
- [x] 03.1-06-PLAN.md — Check-in: qr_flutter (legitimacy gate), CheckInBloc, reorder/rename/delete, card rail [checkpoint]
- [x] 03.1-07-PLAN.md — SettingsBloc, unit switch (bridged convert), Your data / General / During a workout sections

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03.1-08-PLAN.md — History screen, WorkoutDetail, Calendar, DayOverride sheets, HistoryBloc
- [x] 03.1-09-PLAN.md — BodyweightBloc, body-weight sheet, goal sheet
- [x] 03.1-10-PLAN.md — Settings Equipment, Appearance, Data, footer [device check incl. restart persistence]

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 03.1-11-PLAN.md — Home: HomeBloc, week strip, Today, welcome/body-weight/streak cards [device check]
- [x] 03.1-12-PLAN.md — Stats: StatsBloc, tiles, heatmap, EffortCard, body-weight chart, exercise progress [device check]

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 03.1-13-PLAN.md — UI-07 checklist across Phase 3 + 3.1, UI-08/architecture audits, end-to-end offline device check
**UI hint**: yes

### Phase 4: Muscle Map Rendering

**Goal**: The body map is drawn natively with the same fatigue and volume shading as openGym
**Depends on**: Phase 3
**Requirements**: MAP-01, MAP-02, MAP-03
**Success Criteria** (what must be TRUE):

  1. Front/back and male/female body maps render from `body-paths.js`
  2. Shading matches openGym's for the same workout history
  3. Tapping a muscle opens the muscle view

**Plans**: 8 plans in 5 waves
**UI hint**: yes

Plans:
**Wave 1**

- [ ] 04-01-PLAN.md — Vendor recovery-view.js + strength-exercises.js, muscle-view-shim.js (Stats muscle views, hard-set pick, muscleIndex), inventory + fixtures
- [ ] 04-03-PLAN.md — xml legitimacy gate + install, NOTICE (MuscleMap MIT), body-paths.js -> 4 SVG assets generator [checkpoint]

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 04-02-PLAN.md — MusclesJs/RecoveryJs additions, MuscleViewJs facade + models, phase4 dispatch, device parity
- [ ] 04-04-PLAN.md — AppPalette.label, BodyGeometryCache (xml + path_drawing), BodyMapPainter, BodyMap + legends

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 04-05-PLAN.md — Stats Muscle balance / Fatigue / Strength card (MuscleBalanceBloc)
- [ ] 04-06-PLAN.md — /muscles route, MusclesBloc, MuscleExplorer, Library "By muscle"

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 04-07-PLAN.md — Picker "By muscle", RoutineEdit "What this session hits", FinishSummary "What you just trained"

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 04-08-PLAN.md — Phase gates, UI07 checklist closure, device walkthrough vs openGym [checkpoint]

### Phase 5: Timers & Guest Mode

**Goal**: Rest alerts fire even when the app is backgrounded, and the app runs fully as a guest with no account and no server
**Depends on**: Phase 4
**Requirements**: TMR-01, TMR-02, TMR-03, AUTH-05
**Scope change (2026-09-30, user decision)**: guest mode only, no online sync. Server URL, passkey, pairing and logout (AUTH-01..04) are out of scope.
**Success Criteria** (what must be TRUE):

  1. Backgrounding during rest gives an exact notification at the end of rest (Android + iOS)
  2. The daily reminder fires at the configured time
  3. The app runs as a guest with no server: no sign-in screen, no account or server UI, and no network calls for user data

**Plans**: 8 plans

Plans:
**Wave 1**

- [x] 05-01-PLAN.md — Legitimacy gate + install 6 packages, Android/iOS notification config (SCHEDULE_EXACT_ALARM, no USE_EXACT_ALARM), timer tone WAVs [checkpoint]
- [x] 05-02-PLAN.md — Bridge supersetFlow.js rest decisions + mobile.js buildReminderNotifications shim, facades, fixtures, device parity
- [x] 05-03-PLAN.md — AUTH-05 guest-only audit (tool/guest_audit.sh), ApiClientFactory rule comment, UI-07 account rows N/A

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 05-04-PLAN.md — NotificationService (tz, exact/inexact), TimerSound (tones, vibration, play-on-silent), WakelockSync, DI/boot

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 05-05-PLAN.md — WorkoutTimerBloc (useUI.js rest + work slice), RestTimerBar, TimerFlash, lifecycle host, background rest notification
- [x] 05-06-PLAN.md — ReminderSync (mobile.js syncReminder), Settings Notifications section, During-a-workout rows

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 05-07-PLAN.md — WorkoutBloc rest/work triggers, set/finish beeps, timed-set Start button

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 05-08-PLAN.md — Phase gates, UI-07 timer rows, real-device walkthrough Android + iPhone [checkpoint]
**UI hint**: yes

### Phase 6: Local Backup & Restore

**Goal**: The user's data is always backed up to a device folder they choose, and a backup file restores everything, with no data ever sent online
**Depends on**: Phase 5
**Requirements**: BAK-01, BAK-02, BAK-03, BAK-04, IMP-04
**Scope change (2026-09-30, user decision)**: replaces Server Sync (SYNC-01..03). The backup file is the "master" copy: importing it restores all user data, like signing in again after a logout.
**Success Criteria** (what must be TRUE):

  1. The user picks a backup folder on the device, and can change it any time in Settings
  2. A full-state JSON backup is written to that folder regularly without user action
  3. The user can make a backup at any time from Settings
  4. Importing a backup file on a fresh install restores all user data exactly (round-trip equivalent)

**Plans**: 8 plans in 5 waves

Plans:
**Wave 1**

- [x] 06-01-PLAN.md — Legitimacy gate + install file_picker, share_plus (wave 1)
- [x] 06-02-PLAN.md — BackupSettings model, sqflite DAO, iOS security-scoped bookmark Method Channel (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 06-03-PLAN.md — BackupFolderService (SAF + iOS bookmarks), BackupRepository (backup write + share export)
- [x] 06-04-PLAN.md — BackupImportService (file picker, JSON validation, GymState preparation)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 06-05-PLAN.md — Settings Data section UI (D-12 row order), SettingsBloc backup events/handlers
- [x] 06-06-PLAN.md — Fresh-install restore offer (D-14), first-workout folder prompt (D-02), folder-unavailable snackbar (D-04)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 06-07-PLAN.md — Auto-backup triggers: workout finish (D-06a), routine editor exit (D-06b), app background (D-06c)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 06-08-PLAN.md — Phase gates, round-trip verification, device walkthrough Android + iOS [checkpoint]
**UI hint**: yes

### Phase 7: Coach & Admin

**Goal**: The AI Coach and the admin panel work the same way as in openGym
**Depends on**: Phase 6
**Requirements**: COACH-01, COACH-02, COACH-03, ADM-01, ADM-02, ADM-03
**Success Criteria** (what must be TRUE):

  1. User can finish coach setup/intake and chat, with replies that use their training data
  2. Admin can manage users, invites and the audit log

**Plans**: TBD
**UI hint**: yes

### Phase 8: Import, Share & i18n

**Goal**: The user can bring data in or out of the app and use it in their own language
**Depends on**: Phase 7
**Requirements**: IMP-01, IMP-02, IMP-03, I18N-01, I18N-02
**Success Criteria** (what must be TRUE):

  1. A Hevy/CSV export imports with correct exercise matching
  2. A plan shared as a QR code imports on another device; gym card barcodes scan
  3. Switching to any of the 14 locales translates the UI and exercise names

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 (user approval between phases)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Models | 7/7 | Complete    | 2026-09-25 |
| 2. Core Logic via QuickJS | 8/8 | Complete | 2026-09-28 |
| 3. BLoC & UI Translation | 16/16 | Complete | 2026-09-29 |
| 3.1. History, Stats, Home, Check-in & Settings | 13/13 | Complete | 2026-09-30 |
| 4. Muscle Map Rendering | 8/8 | Complete | 2026-09-30 |
| 5. Timers & Guest Mode | 8/8 | Complete | 2026-09-30 |
| 6. Local Backup & Restore | 0/8 | Not started | - |
| 7. Coach & Admin | 0/TBD | Not started | - |
| 8. Import, Share & i18n | 0/TBD | Not started | - |
