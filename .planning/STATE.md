# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-24)

**Core value:** Log a workout fully offline with exactly the same numbers as openGym.
**Current focus:** Phase 1: Foundation & Models

## Current Position

Phase: 1 of 8 (Foundation & Models)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-09-24 — Project initialized (PROJECT, REQUIREMENTS, ROADMAP)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: Run openGym lib JS in QuickJS, bundled with esbuild (no ESM in flutter_js)
- [Init]: Auth = native passkey + pairing-code fallback
- [Init]: Local-first with server sync; full scope in v1
- [Init]: User approves each phase before the next one starts
- [Phase 1]: Round-trip fixture is synthetic (user accepted 2026-09-25, no real file available)
- [Project, 2026-09-25]: NO TESTS rule (CLAUDE.md + hook). Phase 1 plans keep their test content; executors must SKIP every test task/step, test file and test dev-dependency, and verify with `flutter analyze` + source/CLI checks instead
- [Project, 2026-09-25]: JS-03 parity is verified by a `tool/` parity script, not Dart tests

### Pending Todos

None yet.

### Blockers/Concerns

- flutter_passkey_service: confirm the package exists, is maintained, and works with the server's RP_ID (research in Phase 5)
- Native passkeys need assetlinks.json / AASA on the user's server domain
- flutter_js ships QuickJS on Android but JavaScriptCore on iOS, so parity tests must run on both engines

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-09-25
Stopped at: Session resumed, proceeding to plan-phase 1 research (no CONTEXT.md, --skip-ui)
Resume file: .planning/phases/01-foundation-models/.continue-here.md
