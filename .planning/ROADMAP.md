# Roadmap: open_exercise (openGym → Flutter)

## Overview

Port openGym to native Flutter in horizontal layers. Build the data foundation first, then the original JS logic running in QuickJS, then the UI on top of both. Muscle map, timers/auth, sync and the extended features (Coach, Admin, Import/Share, i18n) follow. Each phase waits for user approval before the next one starts.

## Phases

- [x] **Phase 1: Foundation & Models** - Folder structure, OpenAPI models + Dio clients, state models, sqflite schema (completed 2026-09-25)
- [ ] **Phase 2: Core Logic via QuickJS** - Bundle openGym lib JS, JsEngineService, parity script
- [ ] **Phase 3: BLoC & UI Translation** - State layer, Library, exercise detail, workout tracker, plan/routines in Material 3
- [ ] **Phase 3.1: History, Stats, Home, Check-in & Settings** (INSERTED) - Remaining screens on the Phase 3 state layer
- [ ] **Phase 4: Muscle Map Rendering** - SVG paths → CustomPainter with fatigue/volume shading
- [ ] **Phase 5: Timers & Passkeys** - Background rest alerts, reminders, passkey + pairing sign-in
- [ ] **Phase 6: Server Sync** - Local-first sync with rev polling and sync-merge.js
- [ ] **Phase 7: Coach & Admin** - AI Coach flows and admin panel
- [ ] **Phase 8: Import, Share & i18n** - Hevy/CSV import, QR/barcode, backup, 14 locales

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

**Plans**: TBD
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

**Plans**: TBD
**UI hint**: yes

### Phase 4: Muscle Map Rendering

**Goal**: The body map is drawn natively with the same fatigue and volume shading as openGym
**Depends on**: Phase 3
**Requirements**: MAP-01, MAP-02, MAP-03
**Success Criteria** (what must be TRUE):

  1. Front/back and male/female body maps render from `body-paths.js`
  2. Shading matches openGym's for the same workout history
  3. Tapping a muscle opens the muscle view

**Plans**: TBD
**UI hint**: yes

### Phase 5: Timers & Passkeys

**Goal**: Rest alerts fire even when the app is backgrounded, and the user can sign in to their server
**Depends on**: Phase 4
**Requirements**: TMR-01, TMR-02, TMR-03, AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):

  1. Backgrounding during rest gives an exact notification at the end of rest (Android + iOS)
  2. The daily reminder fires at the configured time
  3. User can sign in with a passkey (on a correctly associated domain) or a pairing code, and log out
  4. Guest mode works with no server

**Plans**: TBD
**UI hint**: yes

### Phase 6: Server Sync

**Goal**: Local data and server data stay in sync, with conflicts merged the same way openGym merges them
**Depends on**: Phase 5
**Requirements**: SYNC-01, SYNC-02, SYNC-03
**Success Criteria** (what must be TRUE):

  1. A workout logged offline appears on the server after reconnecting
  2. Changes made in the web app appear in the Flutter app within 30 s or on resume
  3. Concurrent edits merge through `sync-merge.js` without data loss

**Plans**: TBD

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
**Requirements**: IMP-01, IMP-02, IMP-03, IMP-04, I18N-01, I18N-02
**Success Criteria** (what must be TRUE):

  1. A Hevy/CSV export imports with correct exercise matching
  2. A plan shared as a QR code imports on another device; gym card barcodes scan
  3. Backup and restore work
  4. Switching to any of the 14 locales translates the UI and exercise names

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 (user approval between phases)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Models | 7/7 | Complete    | 2026-09-25 |
| 2. Core Logic via QuickJS | 0/TBD | Not started | - |
| 3. BLoC & UI Translation | 0/TBD | Not started | - |
| 4. Muscle Map Rendering | 0/TBD | Not started | - |
| 5. Timers & Passkeys | 0/TBD | Not started | - |
| 6. Server Sync | 0/TBD | Not started | - |
| 7. Coach & Admin | 0/TBD | Not started | - |
| 8. Import, Share & i18n | 0/TBD | Not started | - |
