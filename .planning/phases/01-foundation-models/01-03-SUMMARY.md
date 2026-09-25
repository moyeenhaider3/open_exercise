---
phase: 01-foundation-models
plan: 03
subsystem: database
tags: [dart-models, json, equatable, passthrough, sqflite-prep, workout-model]

# Dependency graph
requires:
  - phase: 01-foundation-models
    provides: "01-01: flutter_bloc/equatable/sqflite/dio/collection installed, strict-casts/strict-raw-types analyzer, AGPL headers"
provides:
  - "tool/fixtures/state_sample.json: deterministic synthetic FND-03/FND-04 round-trip fixture (32 workouts) covering dropsets, rest-pause clusters, warm-up phase, per-side sets, supersets, explicit nulls, unknown keys, a malformed value"
  - "tool/fixtures/gen_state_fixture.mjs: regenerates the fixture byte-identically from openGym's demoSeed.js"
  - "JsonReader / emit() (lib/core/models/json_passthrough.dart): shared known-fields-plus-extra JSON parsing helper for every future state model"
  - "Workout, WorkoutEntry, SetEntry, DropEntry, ClusterEntry, SideSets (lib/core/models/): passthrough-safe models for the workout/set portion of state-<uid>.json"
affects: [01-04, 01-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "JsonReader(source, known: {...}) pattern: known keys read via typed getters (string/integer/number/boolean/map/list/stringList/objectList<T>); anything absent -> null+untouched, anything null/wrong-typed/unknown -> demoted into `extra` unchanged"
    - "emit(extra, typed) = {...extra, ...typed-with-nulls-stripped} for toJson()"
    - "No `as` casts in lib/core/models -- only `is`/Dart 3 `case final Type x` patterns, enforced by a grep gate (required by strict-casts)"
    - "resolvedPhase/resolvedType getters mirror workout-model.js field-resolution logic only (no volume/1RM math -- that stays in JS per JS-04)"
    - "Fixture generator pins globalThis.Date and Math.random before dynamically importing openGym's own JS so the same demo generator run is byte-identical every time"

key-files:
  created:
    - tool/fixtures/gen_state_fixture.mjs
    - tool/fixtures/state_sample.json
    - lib/core/models/json_passthrough.dart
    - lib/core/models/set_entry.dart
    - lib/core/models/workout.dart
  modified: []

key-decisions:
  - "FIXTURE PATH DEVIATION (orchestrator decision, pre-recorded in this plan's no-tests rule note): fixture lives at tool/fixtures/state_sample.json, not test/fixtures/state_sample.json -- writes under test/ are blocked by the project's no-tests PreToolUse hook. Plans 01-04/01-06 must read from tool/fixtures/state_sample.json."
  - "test/core/models/workout_test.dart was NOT created -- the no-tests rule blocks all test/ writes. The plan's <behavior> block was instead exercised with a transient (uncommitted) `dart run` script against the fixture, then deleted before committing; every behavior assertion passed (see 'Skipped (no-tests rule)' below)."
  - "demoSeed.js imports cleanly under plain `node` (no npm deps in its import chain: format.js -> i18n-core.js, starter.js, history.js -> workout-model.js/exercises.js -> exercises-data.js, all plain ES modules) -- the plan's node-import-failure fallback (hand-authoring 6 workouts) was not needed."
  - "Added JsonReader.stringList(key) beyond the plan's four named typed-read methods (string/integer/number/boolean/map/list/objectList) -- needed for Workout.routineIds/prs (List<String>?), which the plan's action step requires ('accept only lists whose every element is a String') but doesn't map onto any listed JsonReader method. This is additive, not a deviation from any explicit instruction."

patterns-established:
  - "Every state-shape model built on JsonReader: known fields typed, everything else preserved verbatim in `extra`, toJson() = emit(extra, typedFields)"
  - "Fixture regeneration is deterministic and checked into git; `node tool/fixtures/gen_state_fixture.mjs && git diff --quiet tool/fixtures/state_sample.json` is the freshness check for future fixture edits"

requirements-completed: [FND-03]

# Metrics
duration: ~28min
completed: 2026-09-25
---

# Phase 1 Plan 03: Round-Trip Fixture and Workout/SetEntry Models Summary

**Deterministic synthetic state_sample.json fixture (32 workouts, generated from openGym's own demoSeed.js) plus passthrough-safe Workout/WorkoutEntry/SetEntry/DropEntry/ClusterEntry/SideSets Dart models built on a shared JsonReader helper that never drops or alters unknown, null, or wrong-typed JSON.**

## Performance

- **Duration:** ~28 min
- **Completed:** 2026-09-25T09:21:11Z
- **Tasks:** 2/2
- **Files modified:** 5 (all new: 2 fixture files, 3 lib/core/models files)

## Accomplishments
- `tool/fixtures/gen_state_fixture.mjs` dynamically imports `buildDemoState()` from `../openGym/frontend/src/lib/demoSeed.js` and `WC_DEFAULT` from `workout-controls.js`, pins `globalThis.Date` and `Math.random` before the import so the run is byte-identical every time, then hand-augments the result with every FND-03 hard case: a dropset, a rest-pause set, a new-style warm-up + legacy `warmup: true` warm-up, a per-side (`sides.L`/`sides.R`) entry (one side itself a dropset), a two-entry superset (`sg`), an in-progress `active` workout, and passthrough probes (unknown top-level/workout/entry/set keys, an explicit `rir: null`, a malformed string weight `"82.5"`).
- `tool/fixtures/state_sample.json` committed: 32 workouts, all 12 verify markers present, every top-level `DEF` key present, confirmed byte-identical on a second generator run.
- `lib/core/models/json_passthrough.dart`: `JsonReader` class with `string/integer/number/boolean/map/list/stringList/objectList<T>` typed readers, each following the absent->null / present-and-typed->value / present-and-null-or-wrong-typed->demoted-to-extra rule, using only `is`/Dart-3 `case final Type x` patterns (zero `as` casts, verified by grep gate). `emit()` remerges `extra` with non-null typed fields for `toJson()`.
- `lib/core/models/set_entry.dart`: `DropEntry`, `ClusterEntry`, `SideSets`, `SetEntry` (all `Equatable`), covering `phase`/legacy `warmup`, `type`/`drops`/`clusters`, and per-side sets, plus `resolvedPhase`/`resolvedType` getters mirroring `workout-model.js`'s `phaseForSet`/`setType` (field resolution only).
- `lib/core/models/workout.dart`: `WorkoutEntry`, `Workout` (both `Equatable`), used for both completed and in-progress (`active`) workouts, with `Workout.copyWith(...)`.
- `flutter analyze` (whole project): "No issues found!"
- All plan `<behavior>` assertions verified via a transient (deleted, not committed) `dart run` script against the real fixture: every one of the 32 workouts plus the `active` workout round-trips byte-for-byte (`DeepCollectionEquality`), the malformed weight and null `rir` survive, dropset/rest-pause/per-side/superset rows parse correctly, unknown keys survive at every nesting level, two instances from the same map are `==`, and both garbage-input cases (`{'entries': 'nope', 'start': 'x'}` and `{'entries': [1, null, 'a']}`) parse without throwing and round-trip unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Synthesize the state_sample.json fixture from demoSeed.js plus hand augmentation** - `e0625dd` (feat)
2. **Task 2: JsonReader passthrough helper and Workout / WorkoutEntry / SetEntry models** - `19e89ff` (feat)

**Plan metadata:** this SUMMARY commit (docs)

## Files Created/Modified
- `tool/fixtures/gen_state_fixture.mjs` - Deterministic generator: pins clock/rng, imports openGym's own demo builder, hand-augments with every FND-03 hard case
- `tool/fixtures/state_sample.json` - Committed fixture output (32 workouts, fully synthetic)
- `lib/core/models/json_passthrough.dart` - `JsonReader` + `emit()`: shared known-fields-plus-extra parsing helper
- `lib/core/models/set_entry.dart` - `DropEntry`, `ClusterEntry`, `SideSets`, `SetEntry`
- `lib/core/models/workout.dart` - `WorkoutEntry`, `Workout` (+ `copyWith`)

## Decisions Made
- Kept the fixture generator's DEF constant as a literal copy of `useStore.js` lines 23-85 (with a citing comment) rather than importing `useStore.js` itself, since that file pulls in `zustand`, unavailable to a plain-`node` script — exactly as the plan anticipated.
- Distributed the plan's augmentation instructions ("in the last 3 workouts...") one hard case per workout (dropset workout, rest-pause workout, warm-up/per-side/superset workout) rather than cramming all cases into every one of the three, since the plan's wording allows either reading and this keeps each workout's diff-from-generated easy to audit.
- Placed the malformed-weight probe (`w: '82.5'`) on a set in the same workout as the rest-pause case (rather than a fourth workout) since the plan does not require it to be isolated.
- See "FIXTURE PATH DEVIATION" and the `JsonReader.stringList` addition above (frontmatter `key-decisions`).

## Deviations from Plan

### Rule-driven adjustments (no-tests project rule, CLAUDE.md/STATE.md precedence)

**1. [No-tests project rule] Fixture path: tool/fixtures/ instead of test/fixtures/**
- **Found during:** Task 1 (before writing any file)
- **Issue:** Plan's `files_modified` and verify commands reference `test/fixtures/state_sample.json`; the project's PreToolUse hook blocks all writes under `test/`.
- **Fix:** Generator and output both live under `tool/fixtures/` (script already specified at that path by the plan). This was pre-authorized as an orchestrator decision recorded directly in this plan's no-tests-rule note.
- **Files affected:** `tool/fixtures/gen_state_fixture.mjs`, `tool/fixtures/state_sample.json`
- **Verification:** Both files exist and pass every fixture acceptance criterion (verify one-liner, determinism check, DEF-key check) at the new path.
- **Committed in:** `e0625dd`

**2. [No-tests project rule] test/core/models/workout_test.dart not created; RED/GREEN test steps skipped**
- **Found during:** Task 2
- **Issue:** Task 2 is `tdd="true"` and specifies writing `test/core/models/workout_test.dart` first (RED) then implementing (GREEN). The no-tests rule and its PreToolUse hook forbid any write under `test/`.
- **Fix:** Implemented only the production code (`lib/core/models/*.dart`) directly. Exercised every `<behavior>` assertion with a transient `dart run` script (not committed, deleted immediately after passing) against the real fixture, then verified with `flutter analyze`.
- **Files affected:** none under `test/` (none created)
- **Verification:** Transient script printed `ALL PASSED` for every behavior assertion (round-trip equality on all 32 workouts + active, malformed/null-value survival, dropset/restpause/per-side/superset parsing, unknown-key survival at every nesting level, Equatable `==`, and both garbage-input non-throw cases). `flutter analyze` reports "No issues found!".
- **Committed in:** `19e89ff` (production code only; no test artifact exists to commit)

---

**Total deviations:** 2, both driven by the project's mandatory no-tests rule (CLAUDE.md/STATE.md), not ad-hoc executor judgment. Plus one additive method (`JsonReader.stringList`) beyond the plan's literal method list, needed to satisfy an explicit requirement the plan's method list didn't otherwise cover.
**Impact on plan:** No scope creep. The fixture path change was pre-authorized in the plan's own no-tests-rule note; the test-file skip is subtractive (removing test content) per an explicit, pre-existing project constraint; the `stringList` addition is a mechanical consequence of an explicit action-step requirement.

## Issues Encountered
None beyond the no-tests rule substitutions documented above.

## Skipped (no-tests rule, not failures)
- `flutter test test/core/models/workout_test.dart exits 0 with at least 9 tests` — N/A, no automated tests in this project. All 9+ behavior assertions were instead verified via a transient `dart run` script against `tool/fixtures/state_sample.json`; every assertion passed (see Accomplishments above).
- `grep -cE "class SetEntry extends Equatable"` / `"class Workout extends Equatable"` and the `as`-cast grep gate were still run (these are source-file checks, not test-based) — both pass: 1 match each for the class declarations, 0 matches for forbidden `as` casts.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `lib/core/models/{json_passthrough,set_entry,workout}.dart` are ready for Plan 01-04 (sqflite schema) to persist `Workout`/`WorkoutEntry`/`SetEntry.toJson()` output directly into a `raw_json` passthrough column, and for Plan 01-06 to build the remaining `DEF`-shape models (routines, settings, equipment, etc.) on the same `JsonReader`/`emit()` pattern.
- `tool/fixtures/state_sample.json` is the canonical round-trip fixture for both of those plans — read it from `tool/fixtures/`, not `test/fixtures/` (see Deviations).
- No blockers.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: tool/fixtures/gen_state_fixture.mjs
- FOUND: tool/fixtures/state_sample.json
- FOUND: lib/core/models/json_passthrough.dart
- FOUND: lib/core/models/set_entry.dart
- FOUND: lib/core/models/workout.dart
- FOUND: .planning/phases/01-foundation-models/01-03-SUMMARY.md
- FOUND commit: e0625dd (Task 1 commit)
- FOUND commit: 19e89ff (Task 2 commit)
