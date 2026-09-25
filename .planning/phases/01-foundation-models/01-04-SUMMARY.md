---
phase: 01-foundation-models
plan: 04
subsystem: models
tags: [dart-models, json, equatable, passthrough, state-model, gym-state]

# Dependency graph
requires:
  - phase: 01-foundation-models
    provides: "01-03: JsonReader/emit passthrough helper, Workout/WorkoutEntry/SetEntry models, tool/fixtures/state_sample.json fixture"
provides:
  - "Routine/RoutineExercise, BodyweightEntry, Reminder, WorkoutControls, EquipProfile, GymCard, CustomExercise, ExWeight (lib/core/models/): passthrough-safe part models for every remaining DEF shape"
  - "kDefaultState (lib/core/models/default_state.dart): DEF ported 1:1 from useStore.js, plus overlayOnDefaults() reproducing Object.assign(clone(DEF), loaded)"
  - "GymState (lib/core/models/gym_state.dart): the full user-state model every later phase (Blocs, JS bridge, sync, sqflite persistence) reads/writes through"
affects: [01-06, 01-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GymState.fromJson = overlayOnDefaults(json) then JsonReader parse -- every DEF key an older/partial profile is missing is filled from kDefaultState before typed reads happen, mirroring openGym's own loadState() overlay"
    - "Map<String, V> fields (week/dayPlan/exNotes: String; barWeights: num; exWeights: ExWeight) need custom whole-value-or-demote helpers (_stringValueMap/_numValueMap/_exWeightMap in gym_state.dart) since JsonReader only has typed scalar/list/object-list readers, not typed-map-value readers -- a present map with any wrong-typed value is demoted whole (unparsed) into a local `demotions` map merged with reader.extra"
    - "Reminder.tz explicit null survives without any special-casing: JsonReader.string demotes a present-but-null value into `extra` already, so a plain emit(extra, {...,'tz':tz}) reproduces the explicit null; only a genuinely absent key stays absent"

key-files:
  created:
    - lib/core/models/routine.dart
    - lib/core/models/bodyweight_entry.dart
    - lib/core/models/state_parts.dart
    - lib/core/models/default_state.dart
    - lib/core/models/gym_state.dart
  modified: []

key-decisions:
  - "No test/ files created (project no-tests rule, CLAUDE.md/STATE.md precedence) -- both tasks' <behavior> blocks were exercised with a transient (uncommitted, deleted before commit) `dart run` script placed at tool/tmp_verify_taskN.dart against tool/fixtures/state_sample.json; every assertion passed. Verification = flutter analyze + the plan's grep/node one-liners + these transient scripts, per the no-tests rule note in this plan's prompt."

patterns-established:
  - "Every DEF-shape part model follows the same JsonReader/emit skeleton as Workout/SetEntry (Plan 01-03): Equatable, static known-keys Set, factory fromJson via JsonReader, toJson via emit, extra in props, zero `as` casts"
  - "GymState is the single entry point for the whole persisted profile; every later plan (Blocs, sqflite schema, JS bridge, sync) should read/write raw JSON exclusively through GymState.fromJson/toJson, never construct or hand-roll the DEF shape itself"

requirements-completed: [FND-03]

# Metrics
duration: ~35min
completed: 2026-09-25
---

# Phase 1 Plan 04: Routine/BodyweightEntry/State-Parts and GymState Full-State Model Summary

**Every remaining `DEF` key from openGym's useStore.js (settings, routines, bodyweight, equipment profiles, gym check-in cards, reminder, workout controls, and sync metadata `_ts`/`_rev`) modelled as a typed, passthrough-safe `GymState` built on the existing `JsonReader`/`emit` helper, with `kDefaultState` reproducing openGym's own `Object.assign(clone(DEF), loaded)` overlay.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-09-25
- **Tasks:** 2/2
- **Files modified:** 5 (all new)

## Accomplishments
- `lib/core/models/routine.dart`: `Routine`/`RoutineExercise` -- routine plan shape (`id`, `name`, `emoji`, `ex: [{id, sets, reps, weight, note?, sg?}]`), unmodelled routine-exercise keys (`mode`, `targets`, `noProg`, coach-bundle metadata, etc.) fall through to `extra`.
- `lib/core/models/bodyweight_entry.dart`: `BodyweightEntry` (`d`, `w`, `t`), one entry per day.
- `lib/core/models/state_parts.dart`: `Reminder` (`on`/`time`/`tz`, explicit `tz: null` preserved), `WorkoutControls` (one bool per `WC_DEFAULT` key: `steppers`, `setShortcuts`, `pairButtons`, `exerciseButtons`), `EquipProfile` (`id`/`name`/`equipment`), `GymCard` (`id`/`label`/`value`/`fmt`), `CustomExercise` (`id`/`name`, catalogue fields deferred to Phase 3 stay in `extra`), `ExWeight` (`w`/`d`).
- `lib/core/models/default_state.dart`: `kDefaultState` -- every `DEF` key and default value from `useStore.js` lines 23-85 (each group comment-cited to its source line), `wc` expanded from `WC_DEFAULT`; `overlayOnDefaults(loaded)` deep-clones `kDefaultState` and shallow-assigns `loaded`'s top-level keys over it, exactly like `Object.assign(clone(DEF), loaded)` -- a loaded `reminder`/`wc`/etc. replaces the default wholesale, never merged field-by-field.
- `lib/core/models/gym_state.dart`: `GymState` -- one nullable typed field per `DEF` key plus `ts`/`rev` (JSON keys `_ts`/`_rev`). `fromJson` overlays onto `kDefaultState` first, then parses via `JsonReader`. Map-typed fields with non-passthrough value types (`week`/`dayPlan`/`exNotes`: `Map<String,String>`; `barWeights`: `Map<String,num>`; `exWeights`: `Map<String,ExWeight>`) get bespoke whole-value-or-demote helpers, since `JsonReader` has no typed-map-value reader. `copyWith` for every field. `GymState.defaults()`, `GymState.defaultTheme == 'dark'`, `GymState.defaultAccent == 'lime'`. No JS-domain math (1RM/volume/progression) anywhere in this model, per JS-04.
- `flutter analyze lib/core/models`: "No issues found!" (both after Task 1 and after Task 2).
- All plan `<behavior>` assertions verified via two transient (deleted, not committed) `dart run` scripts against the real fixture `tool/fixtures/state_sample.json`:
  - Task 1: every routine (including the one with `__futureRoutineKey`) and bodyweight entry round-trips; `Reminder` on/time/tz behavior including explicit `tz: null` preservation; `WorkoutControls` round-trips `WC_DEFAULT` plus an unknown future key; `EquipProfile`/`GymCard`/`CustomExercise`/`ExWeight` round-trip every fixture value; malformed input (`{'ex': 'nope', 'id': 5}`, `{'d': 5, 'w': 'x', 't': null}`, `{'equipment': [1,2,3]}`) never throws and round-trips unchanged.
  - Task 2: `GymState.fromJson(fixture).toJson()` deep-equals the fixture (including `_ts`, `_rev`, `active`, `__futureTopLevel`); `GymState.fromJson({}).toJson()` deep-equals `kDefaultState` (nulls included: `targetW`, `active`, `effort`, `activeEquipId`, `lastGymCardId`, `reminder.tz`); `{'unit': 'lb'}` overlay equals `kDefaultState` with `unit: 'lb'`; `GymState.defaults() == GymState.fromJson({})`; typed access matches fixture values (`accent == 'sky'`, `theme == 'dark'`, `wdec == 2`, `gymCards.first.fmt == 'ean13'`, `equipProfiles.length == 2`, `active!.id == 'active_fixture'`, `workouts.length` matches); `{'workouts': 'x', 'theme': 5}` does not throw and both wrong-typed values re-emit unchanged; `copyWith(theme: 'light', accent: 'red')` changes only those two keys; `defaultTheme`/`defaultAccent` constants match.

## Task Commits

Each task was committed atomically:

1. **Task 1: Routine, BodyweightEntry and state part models** - `20725aa` (feat)
2. **Task 2: kDefaultState and the GymState full-state model** - `99052ff` (feat)

**Plan metadata:** this SUMMARY commit (docs)

## Files Created/Modified
- `lib/core/models/routine.dart` - `Routine`, `RoutineExercise`
- `lib/core/models/bodyweight_entry.dart` - `BodyweightEntry`
- `lib/core/models/state_parts.dart` - `Reminder`, `WorkoutControls`, `EquipProfile`, `GymCard`, `CustomExercise`, `ExWeight`
- `lib/core/models/default_state.dart` - `kDefaultState`, `overlayOnDefaults()`
- `lib/core/models/gym_state.dart` - `GymState` (+ `copyWith`, `defaults()`, `defaultTheme`, `defaultAccent`)

## Decisions Made
- See "No test/ files created" under frontmatter `key-decisions` -- both tasks' TDD RED/GREEN test-file steps were replaced with transient, uncommitted `dart run` verification scripts per the project's mandatory no-tests rule, exactly as Plan 01-03 established.
- `week`/`dayPlan`/`exNotes`/`barWeights`/`exWeights` needed hand-written map-value validation (`_stringValueMap`/`_numValueMap`/`_exWeightMap` in `gym_state.dart`) rather than a `JsonReader` method, because `JsonReader`'s existing readers cover scalars, lists, and lists-of-objects but not typed-value maps. This is additive plumbing needed to satisfy the plan's explicit "Map-typed fields accept a map only when every value has the expected type, otherwise the whole value goes to extra" requirement -- not a scope change.

## Deviations from Plan

### Rule-driven adjustments (no-tests project rule, CLAUDE.md/STATE.md precedence)

**1. [No-tests project rule] test/core/models/state_parts_test.dart and test/core/models/gym_state_test.dart not created; RED/GREEN test steps skipped**
- **Found during:** Task 1 and Task 2 (both `tdd="true"`)
- **Issue:** Both tasks specify writing a test file first (RED) then implementing (GREEN). The no-tests rule and its PreToolUse hook forbid any write under `test/`.
- **Fix:** Implemented only the production code (`lib/core/models/*.dart`) directly. Exercised every `<behavior>` assertion with a transient `dart run` script (`tool/tmp_verify_task1.dart`, `tool/tmp_verify_task2.dart`, both deleted immediately after passing, never committed) against the real fixture, then verified with `flutter analyze` and the plan's grep/node acceptance-criteria one-liners.
- **Files affected:** none under `test/` (none created)
- **Verification:** Both transient scripts printed `ALL PASSED` for every behavior assertion listed in Accomplishments above. `flutter analyze lib/core/models` reports "No issues found!" after each task.
- **Committed in:** `20725aa` (Task 1), `99052ff` (Task 2) -- production code only; no test artifact exists to commit.

### Out-of-scope inclusion (concurrent-wave working-tree race, not an executor action)

**2. `.planning/ROADMAP.md` (1-line change) landed inside the Task 2 commit (`99052ff`)**
- **Found during:** post-commit review of `99052ff`
- **Issue:** This plan's working tree is shared (not an isolated worktree) with the concurrently-running Plan 01-05 wave. Before Task 2's commit, `git status --short` showed `.planning/ROADMAP.md` as unstaged-modified (not one of this plan's `files_modified`, and explicitly out of scope per this plan's instructions: "Do NOT update STATE.md, ROADMAP.md or REQUIREMENTS.md"). I staged and committed only `lib/core/models/default_state.dart` and `lib/core/models/gym_state.dart` by explicit path (`git add lib/core/models/default_state.dart lib/core/models/gym_state.dart`), never a wildcard add. Despite that, `git show --stat 99052ff` shows `.planning/ROADMAP.md` (a 1-line change: Phase 1 success criterion `4. flutter analyze and flutter test pass` -> `4. flutter analyze pass`, itself a correct reflection of the project's no-tests rule) included in the same commit -- almost certainly because the concurrent Plan 01-05 process staged that file in the shared index between my `git status` check and my `git commit` call, and a plain `git commit` commits the whole index, not just the paths named in my most recent `git add`.
- **Impact:** The content of the swept-in change is itself correct and harmless (aligns with the already-recorded no-tests decision in STATE.md), but it was not requested by this plan and its authorship/attribution is now folded into a Plan 01-04 commit rather than wherever it was meant to land.
- **Action taken:** None -- attempting to split it out via a follow-up revert commit mid-wave risked colliding with the concurrent plan's own commit of the same intended change (git would then see "nothing to commit" for that file and simply skip it, which is fine) or, worse, reverting a change the other process still depends on seeing on disk. Flagging here for the orchestrator, which owns `ROADMAP.md` after the wave and can reconcile authorship if needed.
- **Files affected:** `.planning/ROADMAP.md` (not modified by me; already present as a working-tree diff before my Task 2 commit)
- **Committed in:** `99052ff` (alongside my two intended files)

---

**Total deviations:** 2. One is the no-tests rule substitution (subtractive, pre-authorized by CLAUDE.md/STATE.md, no scope creep). The other is an unintended side effect of shared-working-tree concurrency with Plan 01-05, not an executor judgment call -- no file under this plan's `files_modified` was affected, and no content I authored was involved.

## Issues Encountered
None beyond the two items documented above.

## Skipped (no-tests rule, not failures)
- `flutter test test/core/models/state_parts_test.dart exits 0 with at least 6 tests` -- N/A, no automated tests in this project. All Task 1 behavior assertions were instead verified via a transient `dart run` script; every assertion passed.
- `flutter test test/core/models/ exits 0` (Task 2) -- N/A, same reason. All Task 2 behavior assertions were instead verified via a transient `dart run` script; every assertion passed.
- The plan's `grep -cE "class ... extends Equatable"`, the `as`-cast grep gate, `grep -c "kDefaultState"`, `grep -cE "'_ts'|'_rev'"` and the node one-liner over `default_state.dart` are still source/CLI checks, not test-based -- all run and all pass (see Accomplishments and the acceptance-criteria commands run during this session).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `lib/core/models/{routine,bodyweight_entry,state_parts,default_state,gym_state}.dart` are ready for Plan 01-06 (sqflite schema / persistence) to read and write the whole profile through `GymState.fromJson`/`.toJson()`, and for the Bloc layer and JS bridge (later phases) to consume typed `GymState` fields instead of hand-parsing raw JSON.
- `GymState` is the single canonical entry point for the persisted profile shape -- no later plan should hand-roll the DEF shape itself.
- No blockers. See "Out-of-scope inclusion" deviation above for one item the orchestrator should be aware of when reconciling `.planning/ROADMAP.md` after this wave.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: lib/core/models/routine.dart
- FOUND: lib/core/models/bodyweight_entry.dart
- FOUND: lib/core/models/state_parts.dart
- FOUND: lib/core/models/default_state.dart
- FOUND: lib/core/models/gym_state.dart
- FOUND: .planning/phases/01-foundation-models/01-04-SUMMARY.md
- FOUND commit: 20725aa (Task 1 commit)
- FOUND commit: 99052ff (Task 2 commit)
