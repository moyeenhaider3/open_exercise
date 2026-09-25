# Requirements: open_exercise (openGym → Flutter)

**Core value:** Log a workout fully offline with exactly the same numbers as openGym.
**Reference:** `../openGym/` (read-only)

## v1 Requirements

### Foundation (FND)
- [x] **FND-01**: App uses a feature-first layout (`lib/core/`, `lib/features/<feature>/{data,bloc,view}`) with flutter_bloc + equatable; every Bloc has sealed State classes and explicit Event classes
- [x] **FND-02**: Dart models and Dio API clients are generated from `../openGym/api/openapi.yaml` and cover every route (auth, pair, data/rev, push, activity, admin)
- [x] **FND-03**: Dart models exist for the full user state (`DEF` in `useStore.js`: settings, bodyweight, routines, week, dayPlan, exWeights, workouts, active, customEx, equipProfiles, exNotes, favEx, barWeights, gymCards, …), including set `phase`/`type`, drops and clusters
- [x] **FND-04**: A sqflite schema stores that state, and importing a representative (synthetic, demoSeed-derived) `state-<uid>.json` then exporting it again gives equivalent JSON (round-trip test). Note: user accepted the synthetic fixture on 2026-09-25 (no real file available)
- [ ] **FND-05**: The app boots to an empty shell with dependency injection, routing and a theme (dark/light, accent) wired up

### Core Logic via QuickJS (JS)
- [ ] **JS-01**: openGym `frontend/src/lib/*.js` domain modules are bundled (esbuild → a single global/IIFE) into a Flutter asset by a reproducible script
- [ ] **JS-02**: `JsEngineService` loads the bundle in flutter_js and exposes typed Dart calls for 1RM, progression, plate/bar math, workout-model helpers, recovery/fatigue, history and session merge
- [ ] **JS-03**: A parity script (a `tool/` CLI script, not a Dart test, per the no-tests rule) runs openGym's test fixtures (onerm, progression, bar, workout-model, recovery) through the Dart bridge and matches the vitest results exactly
- [ ] **JS-04**: No 1RM, progression or plate math is hand-written in Dart (enforced by review)

### UI Translation (UI)
- [ ] **UI-01**: User can browse, search (typo-tolerant), filter by muscle/equipment and favourite exercises in the Library
- [ ] **UI-02**: User can view exercise detail with instructions and the animated WebP/GIF, cached in memory
- [ ] **UI-03**: User can start, run and finish a workout: log sets (straight, warm-up, drop-set, rest-pause), use steppers, see progression suggestions, reorder, swap and supersets
- [ ] **UI-04**: User can create and edit routines and the weekly plan (Plan, RoutineEdit, drag to reorder)
- [ ] **UI-05**: User can view History and Stats (charts, heatmap, 1RM trends, bodyweight)
- [ ] **UI-06**: User can open Home, Check-in and Settings with the same options as openGym (units, rest, sound, theme, accent, workout view, equipment profiles, week start, decimals, reset)
- [ ] **UI-07**: Every Zustand action in `useStore.js`/`useUI.js` has an equivalent Bloc event
- [ ] **UI-08**: All lists use `ListView.builder` (or slivers), and screen layouts match openGym's views 1:1

### Muscle Map (MAP)
- [ ] **MAP-01**: SVG path data from `body-paths.js` is parsed with `xml` + `path_drawing` into cached `Path` objects (front/back, male/female)
- [ ] **MAP-02**: The body map is drawn with a `CustomPainter`, with fatigue/volume shading coming from the JS recovery results
- [ ] **MAP-03**: User can tap a muscle to open the Muscles/MuscleExplorer view

### Timers & Notifications (TMR)
- [ ] **TMR-01**: The in-app rest timer counts down with sound, flash and wakelock, matching openGym settings
- [ ] **TMR-02**: If the app is backgrounded during rest, an exact local notification fires when the rest ends; returning or skipping cancels it
- [ ] **TMR-03**: User can set a daily workout reminder (time + timezone) that fires as a local notification

### Auth (AUTH)
- [ ] **AUTH-01**: User can set a server URL and check it with `/api/health` + `/api/config`
- [ ] **AUTH-02**: User can register and sign in with a native passkey (flutter_passkey_service → `/api/register/*`, `/api/login/*`) when the RP domain supports it
- [ ] **AUTH-03**: User can sign in by redeeming a pairing code (`/api/pair/redeem`)
- [ ] **AUTH-04**: The session token is kept in secure storage; user can log out, or log out of all devices
- [ ] **AUTH-05**: User can use the app as a guest/offline with no account

### Sync (SYNC)
- [ ] **SYNC-01**: While signed in, local state syncs to `/api/data`, and remote revisions are polled (`/api/data/rev`, 30 s, on resume)
- [ ] **SYNC-02**: Conflicts are merged by openGym's `sync-merge.js` running in the JS engine
- [ ] **SYNC-03**: A sync banner shows offline, syncing and conflict status

### Coach (COACH)
- [ ] **COACH-01**: User can complete the coach setup and intake flow
- [ ] **COACH-02**: User can chat with the coach, which uses workout insights (coach-insights.js)
- [ ] **COACH-03**: Coach secrets and device settings are stored securely

### Admin (ADM)
- [ ] **ADM-01**: Admin can list, view and disable users
- [ ] **ADM-02**: Admin can create and revoke invites
- [ ] **ADM-03**: Admin can view and clear the audit log, and use the coach admin view

### Import & Share (IMP)
- [ ] **IMP-01**: User can import workouts from a Hevy export or CSV, with exercise matching
- [ ] **IMP-02**: User can share a plan as a QR code and import one by scanning
- [ ] **IMP-03**: User can store gym cards by scanning barcodes
- [ ] **IMP-04**: User can back up and restore state to and from a file

### i18n (I18N)
- [ ] **I18N-01**: UI text is available in all 14 openGym locales and follows the `lang` setting
- [ ] **I18N-02**: Exercise names and instructions are localized (for example pt-BR)

## v2 Requirements

- Web push via VAPID (`/api/push/*`) — replaced by local notifications in v1
- Home-screen widgets and wearable integration

## Out of Scope

- Flutter web/desktop targets — mobile only, like openGym's Capacitor shells
- Changes to the openGym server or API — the port uses the API as it is
- The MCP server and marketing website — not part of the app
- Hand-translating domain math to Dart — against the parity principle

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01..05 | Phase 1 | Pending |
| JS-01..04 | Phase 2 | Pending |
| UI-01..08 | Phase 3 | Pending |
| MAP-01..03 | Phase 4 | Pending |
| TMR-01..03, AUTH-01..05 | Phase 5 | Pending |
| SYNC-01..03 | Phase 6 | Pending |
| COACH-01..03, ADM-01..03 | Phase 7 | Pending |
| IMP-01..04, I18N-01..02 | Phase 8 | Pending |

**Coverage:** 43/43 v1 requirements mapped ✓
