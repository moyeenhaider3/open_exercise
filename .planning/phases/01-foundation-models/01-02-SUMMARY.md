---
phase: 01-foundation-models
plan: 02
subsystem: infra
tags: [openapi, codegen, dio, retrofit, dart, spike]

# Dependency graph
requires:
  - phase: 01-foundation-models (Plan 01-01)
    provides: license/dependency setup this spike ran against
provides:
  - Generator decision for FND-02 (`option-retrofit`, openapi_retrofit_generator 2.0.4, plain spec, no preprocessing), recorded in 01-CODEGEN-SPIKE.md for Plan 01-05 to consume
  - Spike evidence proving all 30 openapi.yaml operations generate cleanly with 0 `dart analyze` errors
  - Confirmed finding that the generated `State` class is closed (declared-properties-only) and must NOT be used for `/api/data` round-tripping
affects: [01-05 (real Dio client generation), 01-03/01-04 (hand-authored GymState/state model)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "OpenAPI-generated Dio clients via openapi_retrofit_generator (pure Dart, no JVM) — decision only, not yet wired into the app"
    - "Generated closed-class schemas from json_serializable are unsafe for round-tripping open/未知-key payloads; hand-authored Map-backed models own those payloads instead"

key-files:
  created:
    - .planning/phases/01-foundation-models/01-02-SUMMARY.md
  modified:
    - .planning/phases/01-foundation-models/01-CODEGEN-SPIKE.md

key-decisions:
  - "Task 1 (verbatim): ALL codegen packages approved (openapi_generator, openapi_generator_annotations, openapi_retrofit_generator, retrofit, retrofit_generator, json_annotation, json_serializable, build_runner). JDK install: NO — user declined `brew install openjdk@21`; confirmed `java -version` unavailable on this machine."
  - "Consequence of JDK=NO: Spike A (openapi_generator / dart-dio, official OpenAPITools generator) was never run — not a technical failure, withheld by user decision."
  - "Spike B (openapi_retrofit_generator 2.0.4, pure Dart, no JVM) ran against the plain unmodified ../openGym/api/openapi.yaml spec (OpenAPI 3.1.0): 0 dart analyze errors, 30/30 operations generated, the 3.1 oneOf-with-null construct on GET /api/data.state handled cleanly as `State?`, zero manual fixups. No preprocessing was needed, so option-retrofit-preprocessed was never exercised."
  - "Decision: option-retrofit (openapi_retrofit_generator 2.0.4, plain spec, no preprocessing) — recorded in 01-CODEGEN-SPIKE.md, replacing `Decision: PENDING`."
  - "Key finding carried forward: the generated `State` Dart class is closed (one field per declared schema property only); any state key the real app writes that isn't in that declared list would be silently dropped on decode/re-encode. The hand-authored GymState (Plans 01-03/01-04) must own the `/api/data` state payload as a `Map<String, dynamic>`-backed model — the generated `State` class must not be used for storage/round-trip."

patterns-established:
  - "Generator choice for OpenAPI->Dio client codegen is evidence-driven: run real spikes against the actual spec in a scratch directory before choosing, never assume based on package popularity alone."
  - "Schemas without `additionalProperties: true` generate closed classes under json_serializable — treat any 'representative, not enforced' spec schema as a signal to keep a parallel Map-backed model for round-tripping."

requirements-completed: [FND-02]

# Metrics
duration: ~28min (Task 2 evidence commit to plan completion; Task 1 checkpoint resolution time not tracked by this executor)
completed: 2026-09-25
---

# Phase 1 Plan 02: OpenAPI Codegen Spike Summary

**Chose `openapi_retrofit_generator` 2.0.4 (pure Dart, plain unmodified spec) as the FND-02 OpenAPI->Dio generator after a real spike against `../openGym/api/openapi.yaml` cleared 30/30 operations with 0 `dart analyze` errors and zero manual fixups — and confirmed the generated `State` schema is closed, so the hand-authored GymState model must own `/api/data`'s state payload.**

## Performance

- **Duration:** ~28 min (from Task 2 spike-evidence commit `ee4f8ca` to plan completion)
- **Started:** 2026-09-25T08:55:21Z (Task 2 commit)
- **Completed:** 2026-09-25T09:23:04Z
- **Tasks:** 3 (1 blocking-human checkpoint, 1 auto spike, 1 blocking decision checkpoint)
- **Files modified:** 1 (`01-CODEGEN-SPIKE.md`)

## Accomplishments
- Resolved the Task 1 legitimacy/JDK gate: all 8 codegen packages approved by the user; JDK install declined, so only the pure-Dart generator path was in scope.
- Ran a real codegen spike (`openapi_retrofit_generator` 2.0.4) against the actual `../openGym/api/openapi.yaml` (OpenAPI 3.1.0, 29 explicit operationIds / 30 requests) in a scratch directory outside the repo — 0 `dart analyze` errors, all 30 operations present, the 3.1 `oneOf: [State, {type:'null'}]` construct on `GET /api/data`'s `state` field handled correctly as `State?`.
- Recorded the user's Task 3 selection — `option-retrofit` — as `Decision: option-retrofit` plus generator version and "plain spec, no preprocessing" in `01-CODEGEN-SPIKE.md`, unblocking Plan 01-05's real client generation.
- Confirmed and documented a load-bearing constraint for the rest of the phase: the generated `State` class only carries declared schema properties (closed class), so it cannot safely round-trip the app's actual `/api/data` state blob — that responsibility stays with the hand-authored `GymState`/state model from Plans 01-03/01-04.

## Task Commits

Each task was committed atomically:

1. **Task 1: Legitimacy check for codegen packages and JDK install consent** - pre-resolved by orchestrator before this executor started (no commit; answers recorded verbatim in `01-CODEGEN-SPIKE.md` and above)
2. **Task 2: Run generators against openapi.yaml in scratch projects and record evidence** - `ee4f8ca` (docs)
3. **Task 3: Choose the OpenAPI generator for FND-02** - `8dee7d3` (docs)

**Plan metadata:** (this commit, made by this executor after the SUMMARY self-check)

## Files Created/Modified
- `.planning/phases/01-foundation-models/01-CODEGEN-SPIKE.md` - Spike evidence table, findings, recommendation, and final `Decision: option-retrofit` / generator version line
- `.planning/phases/01-foundation-models/01-02-SUMMARY.md` - This summary

## Decisions Made
- **Generator: `option-retrofit`** (`openapi_retrofit_generator` 2.0.4, plain spec, no preprocessing) — the only generator actually spiked, since Spike A (`openapi_generator`/dart-dio) required a JVM the user declined to install. It cleared every acceptance bar: 0 analyze errors, 30/30 operations, clean handling of the OpenAPI 3.1 nullable-oneOf edge case, zero manual fixups.
- **`option-retrofit-preprocessed` not needed**: the plain unmodified 3.1 spec parsed and generated cleanly on the first attempt, so no spec downgrade/preprocessing step is required in `tool/gen_api.sh` for Plan 01-05.
- **State payload ownership**: the generated `State` class must not be used to round-trip `/api/data`'s state — it silently drops any undeclared key. Plans 01-03/01-04's `Map<String, dynamic>`-backed model is the source of truth for that payload; only the other generated `DataClient` methods/fields (`rev`, `baseRev`, etc.) are safe to use as-is from Plan 01-05 onward.

## Deviations from Plan

None - plan executed exactly as written. Task 1 was already resolved by the orchestrator prior to this executor's spawn (per the `<completed_tasks>` continuation context); this executor verified the prior commit, applied the user's verbatim Task 3 selection, and documented both in this SUMMARY.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required. (JDK/Java was declined by the user, not installed; no follow-up action needed unless a future spec change forces reconsideration of `option-dart-dio`.)

## Next Phase Readiness
- Plan 01-05 can proceed straight to running `openapi_retrofit_generator` 2.0.4 against the plain spec — no preprocessing step needed in `tool/gen_api.sh`.
- Plan 01-05 must re-type or raw-decode the `state` field on `GetDataResponse`/`PutDataRequest` rather than routing it through the generated `State` class, per the closed-class finding above.
- `option-dart-dio` remains a documented fallback (not viable on this machine today; would require the user to reverse the JDK decision) if a future spec change ever breaks the retrofit generator.
- No blockers for Plan 01-05.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: .planning/phases/01-foundation-models/01-02-SUMMARY.md
- FOUND: .planning/phases/01-foundation-models/01-CODEGEN-SPIKE.md
- FOUND commit: ee4f8ca (Task 2)
- FOUND commit: 8dee7d3 (Task 3)
- Verified: `Decision: option-retrofit` line present (count=1) in 01-CODEGEN-SPIKE.md
