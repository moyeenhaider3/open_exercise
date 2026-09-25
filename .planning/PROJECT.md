# open_exercise — openGym for Flutter

## What This Is

A native Flutter (Android/iOS) port of **openGym** (`../openGym/`), the self-hosted gym and body-weight tracker. The goal is a 1:1 replica of openGym's features, offline persistence and UI layout, built with native Flutter widgets (Material 3) instead of a React/Capacitor WebView.

## Core Value

Log a workout fully offline with **exactly** the same numbers as openGym. The same inputs must give identical 1RM estimates, progression suggestions, plate math and volume/fatigue results, because the original JavaScript logic runs unchanged.

## Reference Source (read-only)

| Area | Location | Notes |
|------|----------|-------|
| API contract | `../openGym/api/openapi.yaml` (1.5k lines) | ~30 routes: auth, pair, data/rev, push, activity, admin |
| Server | `../openGym/api/server.js` | Node, `@simplewebauthn/server`; per-user `state-<uid>.json` |
| State shape | `../openGym/frontend/src/store/useStore.js` (`DEF`) | settings, bodyweight, routines, week, dayPlan, exWeights, workouts, active, customEx, equipProfiles, exNotes, favEx, barWeights, gymCards, … |
| Domain logic | `../openGym/frontend/src/lib/*.js` | onerm, progression, bar, workout-model, recovery, history, sync-merge, … (ES modules with cross-imports) |
| Exercise DB | `lib/exercises-data.js` (888 KB) | also the muscle batch JSON files |
| Muscle map SVG | `lib/body-paths.js` (94 KB), `components/BodyMap.jsx` | |
| UI | `src/views/*.jsx`, `src/components/*.jsx`, `src/sheets.jsx` (2.2k lines) | |
| State actions | `store/useStore.js`, `store/useUI.js` (Zustand) | |
| Locales | `src/locales/*.js` (14 languages) | |
| Domain notes | `../openGym/CLAUDE.md`, `PROJECT_CONTEXT.md` | set types: straight / dropset / restpause |

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Feature-first structure (`lib/core/`, `lib/features/`) using flutter_bloc + equatable (sealed states, explicit events, logic only inside Blocs)
- [ ] Dart models + Dio clients generated from `openapi.yaml`
- [ ] sqflite schema that mirrors the `state-<uid>.json` structure and round-trips it without loss
- [ ] openGym `lib/*.js` bundled as a Flutter asset and run through flutter_js (QuickJS) by a `JsEngineService`. No hand translation of 1RM, progression or plate math.
- [ ] Parity script (not tests): JS engine output matches openGym's vitest fixtures
- [ ] Exercise library, workout tracker, routines/plan, history, stats, settings translated to Material 3, with `ListView.builder` lists and memory-cached WebP/GIF media
- [ ] Muscle map: SVG path strings parsed with `xml` + `path_drawing` and drawn with `CustomPainter`, keeping the fatigue/volume shading
- [ ] Rest timer and reminders with flutter_local_notifications (exact alarm when the app is backgrounded)
- [ ] Auth: native passkey (flutter_passkey_service) where the RP domain supports it, plus the device-pairing code flow (`/api/pair/redeem`) as a fallback
- [ ] Local-first sync with `/api/data` + `/api/data/rev`, merged through `sync-merge.js`
- [ ] AI Coach (CoachChat / Setup / Intake)
- [ ] Admin panel (users, invites, audit)
- [ ] Import and share: Hevy/CSV import, plan share through QR, barcode scanning for gym cards
- [ ] i18n for all 14 openGym locales, including exercise names

### Out of Scope

- Web/desktop Flutter targets — mobile only, matching openGym's Capacitor shells
- Changes to the openGym server — the port uses the API as it is
- The MCP server and marketing website — not part of the app

## Context

- openGym's own mobile app cannot run the WebAuthn ceremony inside its WebView (`server.js:506`) and uses one-time pairing codes. Native passkeys need `assetlinks.json` / `apple-app-site-association` on the `RP_ID` domain, so pairing is the dependable fallback.
- The `lib/*.js` files are ES modules that import each other, and flutter_js can't resolve imports. They must be bundled (esbuild → a single IIFE/global) at build time.
- openGym is local-first: `gym_state_v1` in localStorage, with sync by revision polling (30 s) and a merge.
- Web Service Worker push (`sw.js`, `/api/push/rest-timer`) becomes local notifications.

## Constraints

- **License:** AGPL-3.0-or-later. This port is a derivative work and must use the same license.
- **Stack (user-mandated):** flutter_bloc, equatable, sqflite, Dio (OpenAPI-generated), flutter_js, flutter_local_notifications, flutter_passkey_service, xml, path_drawing.
- **Process:** one phase at a time. Wait for user approval before starting each next phase.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Run the original JS through QuickJS instead of translating it | Keeps the math identical | — Pending |
| Bundle `lib/*.js` with esbuild into one asset | flutter_js has no ESM import resolution | — Pending |
| Passkeys + pairing-code fallback | Native WebAuthn depends on domain association files | — Pending |
| Local-first + server sync | Same as openGym's model | — Pending |
| Full scope in v1 (Coach, Admin, Import/Share, i18n) | User wants a 1:1 replica | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-24 after initialization*
