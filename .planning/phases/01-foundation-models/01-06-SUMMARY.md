---
phase: 01-foundation-models
plan: 06
subsystem: database
tags: [sqflite, persistence, schema, round-trip, gym-state, offline]

# Dependency graph
requires:
  - phase: 01-foundation-models (Plan 01-04)
    provides: "GymState (fromJson/toJson/copyWith), kDefaultState/overlayOnDefaults -- the single typed entry point this repository reads/writes raw state documents through"
provides:
  - "lib/core/db/schema.dart: Tables constants, kSchemaVersion=1, kCreateStatementsV1 (user_state/workouts/routines/bodyweight + 3 indexes)"
  - "lib/core/db/app_database.dart: AppDatabase.open(factory, path) (injectable DatabaseFactory), AppDatabase.defaultPath()"
  - "lib/core/data/gym_state_repository.dart: GymStateRepository.importState/exportState/loadState/saveState/deleteState -- FND-04 offline persistence"
affects: ["Phase 2 (Blocs read/write GymState through GymStateRepository)", "Phase 3 (History/Stats queries the indexed workouts/bodyweight tables directly)", "Phase 6 (sync layer's own active-stripping/_rev-stamping wraps this repository, never modifies it)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hybrid sqflite schema: one opaque doc_json document for every scalar/settings top-level key (order-irrelevant, key-presence-preserving) plus one array table per top-level list key (workouts/routines/bodyweight), each keyed on (uid, pos) -- never (uid, id) -- because array order is significant and real data may repeat or omit ids"
    - "Tri-state *_present column (null/0/1) on user_state: null = key absent, 1 = present as a List (rows written, rebuilt on export), 0 = present but not a List (left untouched inside doc_json, no rows written) -- this is what lets exportState tell absent vs [] vs a malformed value apart without ever guessing"
    - "importState runs one db.transaction wrapping a delete-then-insert Batch, so a failure mid-write leaves the previous state intact (no partial import)"
    - "Repository never touches active or _rev -- that stripping/stamping is PUT /api/data server-side behaviour (../openGym/api/server.js), out of scope for local import/export (Research Pitfall 5)"

key-files:
  created:
    - lib/core/db/schema.dart
    - lib/core/db/app_database.dart
    - lib/core/data/gym_state_repository.dart
  modified: []

key-decisions:
  - "No test/ files created (project no-tests rule, CLAUDE.md/STATE.md precedence, hook-enforced). Both tasks' RED/GREEN test-file steps were replaced with throwaway (uncommitted, deleted after use) dart run scripts run against a scratch Dart project outside the repo (since sqflite_common_ffi cannot be added to the app pubspec) -- see 'How FND-04 was verified' below for the exact method and result."
  - "*_present columns are tri-state (null/0/1), not boolean-present (as the plan's prose could be read literally) -- a plain present/absent flag cannot distinguish a present List (rebuild from rows) from a present non-List value (already sitting in doc_json, must not be overwritten by an empty rebuilt list). This is required for the plan's own stated goal: absent vs [] vs malformed distinct on export."

patterns-established:
  - "Any later plan adding a new top-level array key to GymState (none currently planned) should follow the same (uid, pos)-keyed table + tri-state presence-flag pattern, not (uid, id)."
  - "GymStateRepository is the only supported way to persist/read a GymState locally -- later Bloc/JS-bridge/sync code should call importState/exportState/loadState/saveState, never hand-roll SQL against these tables."

requirements-completed: [FND-04]

# Metrics
duration: ~40min
completed: 2026-09-25
---

# Phase 1 Plan 06: sqflite Schema and GymStateRepository (FND-04) Summary

**Hybrid sqflite schema (one opaque `doc_json` settings document plus `(uid, pos)`-keyed `workouts`/`routines`/`bodyweight` array tables with indexed query columns) and a `GymStateRepository` proven, against the project's real fixture, to round-trip `importState -> exportState` byte-for-byte equivalent JSON -- including array order, duplicate/missing ids, `active`, `_ts`/`_rev`, unknown top-level keys, and SQL-metacharacter uids.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-09-25
- **Tasks:** 2/2 (both `tdd="true"`; test-file steps replaced with throwaway verification scripts per the no-tests rule)
- **Files modified:** 3 (all new)

## Accomplishments
- `lib/core/db/schema.dart`: `Tables` (table/column name constants), `kSchemaVersion = 1`, `kCreateStatementsV1` -- `user_state` (`doc_json` + `ts`/`rev` query copies + tri-state `workouts_present`/`routines_present`/`bodyweight_present`), `workouts`/`routines`/`bodyweight` (each `PRIMARY KEY(uid, pos)`, `raw_json NOT NULL`, typed index columns), 3 indexes (`idx_workouts_uid_d`, `idx_workouts_uid_id`, `idx_bodyweight_uid_d`).
- `lib/core/db/app_database.dart`: `AppDatabase.open({required DatabaseFactory factory, required String path})` runs every `kCreateStatementsV1` statement in one `Batch` inside sqflite's own `onCreate` transaction; `onUpgrade` is a no-op v1 placeholder with a migration-point comment; `AppDatabase.defaultPath()` joins the platform databases directory with `open_exercise.db`.
- `lib/core/data/gym_state_repository.dart`: `GymStateRepository` with `importState`/`exportState`/`loadState`/`saveState`/`deleteState`. `importState` deletes-then-inserts inside one `db.transaction` (partial-write-safe); the three array keys are split into rows (`pos` = index, `raw_json` = exact element, typed columns via `is`-checks that degrade to `NULL` on a type mismatch, never throwing); every other key (including `_ts`, `_rev`, `active`, and any key this model doesn't know about) stays inside one `doc_json` document, untouched. `exportState` rebuilds each array key from its table only when the tri-state presence flag says it was stored as a `List`; otherwise the original value already sits inside `doc_json` and is left alone -- this is what keeps absent vs `[]` vs a malformed non-list value distinct across the round trip.
- Only `db.insert`/`db.query`/`db.delete`/`db.batch` with bound `whereArgs` are used anywhere in the repository -- confirmed by grep (`rawQuery|rawInsert|rawUpdate|rawDelete|execute\(` matches nothing in the file, and no interpolated raw-SQL call exists anywhere under `lib/`).
- `grep -c "Tables\." lib/core/data/gym_state_repository.dart` = 45 -- every table/column reference goes through the `Tables.*` constants from `schema.dart` (plan-checker warning applied), never a string literal.
- `grep -cE "remove\('active'\)|'_rev'\] *="` on the repository file = 0 -- confirmed the repository never strips `active` or restamps `_rev` (that is `PUT /api/data` server-side behaviour, `../openGym/api/server.js` lines ~935-945, out of scope here per Research Pitfall 5).
- `flutter analyze` (whole project): "No issues found!"

## How FND-04 was verified (no-tests rule)

Per the project's mandatory no-tests rule, `test/core/db/schema_test.dart` and `test/core/db/round_trip_test.dart` were never created (a PreToolUse hook also blocks any write under `test/`). Instead, every `<behavior>` assertion from both tasks was exercised by a throwaway (never committed, never under `test/`) `dart run` script, following the pattern the STATE.md decision explicitly authorizes for a headless sqflite check: since `sqflite_common_ffi` cannot be added to the app's `pubspec.yaml` (dev-only test dependency, forbidden by the no-tests rule), verification ran in a **separate scratch Dart project outside the repo**, at:

```
/private/tmp/claude-501/-Users-apple-projects-learning-project-open-exercise/901825d5-954a-4534-9215-f819bece34ef/scratchpad/roundtrip-check/{task1,task2}/
```

Each scratch project has its own `pubspec.yaml` (`sqflite_common_ffi`, `path`, `collection`, `equatable` -- never touching the repo's `pubspec.yaml`) and a **verbatim copy** of the relevant repo source (`lib/core/db/schema.dart`, `lib/core/db/app_database.dart`, `lib/core/data/gym_state_repository.dart`, `lib/core/models/*.dart`, `tool/fixtures/state_sample.json`), with exactly one mechanical edit: `import 'package:sqflite/sqflite.dart'` -> `import 'package:sqflite_common/sqflite.dart'` in the two db files, because `package:sqflite` is a Flutter plugin (platform channels) that cannot run under a plain `dart run` script, whereas `package:sqflite_common` (the API surface `package:sqflite` itself re-exports, confirmed by reading the installed `sqflite-2.4.4`/`sqflite_common-2.5.13` package sources) provides the identical `Database`/`DatabaseFactory`/`OpenDatabaseOptions`/`Batch` types that `sqflite_common_ffi`'s `databaseFactoryFfi` implements. No repo file was modified for this -- the swap exists only in the throwaway copies.

**Task 1 (`verify_task1.dart`), result: `ALL PASSED`:**
- Opening `AppDatabase` with `databaseFactoryFfi` at an in-memory path creates all four tables (`sqlite_master` query).
- All three indexes exist (`idx_workouts_uid_d`, `idx_workouts_uid_id`, `idx_bodyweight_uid_d`).
- `PRAGMA user_version` == 1 after open.
- `workouts` columns are exactly `uid, pos, id, d, start, end_ms, routine_id, raw_json` (8 columns, `PRAGMA table_info`).

**Task 2 (`verify_task2.dart`), result: `ALL PASSED` (9/9 behavior cases against the real `tool/fixtures/state_sample.json`):**
1. `importState('u1', fixture)` then `exportState('u1')` is `DeepCollectionEquality`-equal to the fixture, including workout array order, `active` (`id == 'active_fixture'`), `_ts == 1790000000000`, `_rev == 42`, and the unknown top-level key `__futureTopLevel`. (The fixture has no malformed bodyweight `w` value or duplicate/missing workout ids -- confirmed by inspection -- so those specific sub-cases from the plan's `<behavior>` prose were exercised with synthetic data in cases 2/3 below instead of the fixture itself.)
2. A doc without `workouts`/`routines`/`bodyweight` exports without those keys; `{'workouts': []}` exports `{'workouts': []}`; `{'workouts': 'bad'}` exports `{'workouts': 'bad'}` unchanged.
3. Two workouts sharing `id: 'w1'` plus one workout with no `id` at all -- all three rows survive, in the original order.
4. Re-importing a different doc for `'u1'` fully replaces it (old rows gone, no leftovers); a concurrently-imported `'u2'` is untouched.
5. `exportState('missing')` returns `null`.
6. `loadState('u1')` (after importing the fixture) equals `GymState.fromJson(fixture)`; `loadState('missing')` returns `null`.
7. `saveState('u1', GymState.fromJson(fixture).copyWith(theme: 'light'))` then `exportState('u1')['theme'] == 'light'` and every other top-level key matches the `copyWith` result's own `toJson()` unchanged.
8. A uid containing SQL metacharacters (`"x'); DROP TABLE workouts;--"`) imports and exports the fixture correctly; all four tables still exist afterwards (parameter binding via `whereArgs` throughout, confirmed no raw/interpolated SQL anywhere in the repository).
9. Every fixture workout's row in the `workouts` table has a non-empty `d` column (the indexed column Phase 3 History/Stats will query).

Both scratch projects and scripts were deleted from `/private/tmp/...` after this verification completed; nothing under them was ever copied into the repository.

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema v1 and AppDatabase opener** - `9432d14` (feat)
2. **Task 2: GymStateRepository and the FND-04 round-trip test** - `e52ef80` (feat)

**Plan metadata:** this SUMMARY commit (docs)

## Files Created/Modified
- `lib/core/db/schema.dart` - `Tables`, `kSchemaVersion`, `kCreateStatementsV1` (schema v1: 4 tables, 3 indexes)
- `lib/core/db/app_database.dart` - `AppDatabase.open()` (injectable `DatabaseFactory`), `AppDatabase.defaultPath()`
- `lib/core/data/gym_state_repository.dart` - `GymStateRepository` (`importState`/`exportState`/`loadState`/`saveState`/`deleteState`), `kLocalGuestUid`

## Decisions Made
- See "*_present columns are tri-state" under frontmatter `key-decisions` -- required to keep absent/`[]`/malformed distinguishable on export, which a plain boolean flag cannot do.
- See "How FND-04 was verified" above for the no-tests-rule verification method (throwaway scratch Dart projects outside the repo, never committed).

## Deviations from Plan

### Rule-driven adjustments (no-tests project rule, CLAUDE.md/STATE.md precedence)

**1. [No-tests project rule] `test/core/db/schema_test.dart` and `test/core/db/round_trip_test.dart` not created; RED/GREEN test steps skipped**
- **Found during:** Task 1 and Task 2 (both `tdd="true"`)
- **Issue:** Both tasks specify writing a test file first (RED) then implementing (GREEN), including a dependency on `sqflite_common_ffi` (a dev-only test package the no-tests rule forbids adding to `pubspec.yaml`) and a `test/` write (hook-blocked).
- **Fix:** Implemented only the production code (`lib/core/db/*.dart`, `lib/core/data/gym_state_repository.dart`) directly. Exercised every `<behavior>` assertion via throwaway `dart run` scripts in scratch Dart projects **outside the repo** (per this task's explicit instruction, since a headless sqflite check needs `sqflite_common_ffi`), verbatim-copying the relevant `lib/` source plus the real `tool/fixtures/state_sample.json` fixture. See "How FND-04 was verified" above for full detail and results.
- **Files affected:** none under `test/` (none created)
- **Verification:** Both throwaway scripts printed `ALL PASSED` for every `<behavior>` assertion (4 for Task 1, 9 for Task 2). `flutter analyze` (whole project) reports "No issues found!"
- **Committed in:** `9432d14` (Task 1), `e52ef80` (Task 2) -- production code only; no test artifact exists to commit.

**2. [Rule 1 - minor, plan-source drift] Fixture has no malformed `bodyweight.w` value or duplicate/missing-id workouts**
- **Found during:** Task 2 verification-script authoring
- **Issue:** The plan's Task 2 `<behavior>` prose describes the fixture as containing "the malformed w '82.5'" and workouts behavior around duplicate/missing ids that would be exercised directly against `tool/fixtures/state_sample.json`. Inspecting the actual fixture (`python3 -c "json.load(...)"`) shows every `bodyweight.w` value is numeric and every `workouts[].id` is unique and present -- these specific edge cases are not present in the real fixture as committed.
- **Fix:** No fixture change (out of scope for this plan; the fixture is a shared Phase 1 asset). The two edge cases (duplicate/missing workout ids; malformed-list-value handling in general) were instead verified with small synthetic documents constructed inline in `verify_task2.dart` (cases 2 and 3), exercising the exact same `GymStateRepository` code paths the fixture-based case (1) exercises for everything else.
- **Files affected:** none (verification-only; no repo file touched)
- **Verification:** `verify_task2.dart` cases 2/3 both print `PASS`.
- **Committed in:** n/a (verification-only observation, no code change)

---

**Total deviations:** 2. Both are no-tests-rule/verification-method substitutions (subtractive/additive-verification-only, pre-authorized by CLAUDE.md/STATE.md), not scope creep against the plan's production code.

## Issues Encountered
None beyond the two items documented above.

## Skipped (no-tests rule, not failures)
- `flutter test test/core/db/schema_test.dart exits 0 with at least 4 tests` (Task 1) -- N/A, no automated tests in this project. Substituted: throwaway `verify_task1.dart` against `databaseFactoryFfi`, 4/4 assertions passed (see "How FND-04 was verified").
- `flutter test test/core/db/ && flutter analyze` (Task 2's `<verify><automated>`) -- N/A for the `flutter test` half. Substituted: throwaway `verify_task2.dart`, 9/9 behavior cases passed against the real fixture; `flutter analyze` half was run for real and is clean.
- `grep -c "state_sample.json" test/core/db/round_trip_test.dart returns at least 1` / `grep -c "DeepCollectionEquality" ... returns at least 1` -- N/A, that test file was not created. The equivalent fixture load and `DeepCollectionEquality` comparison were performed directly in `verify_task2.dart` instead (both present, used throughout).
- Every other acceptance-criteria grep/CLI check in the plan (PRIMARY KEY count, CREATE INDEX count, kSchemaVersion count, `Tables.` usage count, raw-SQL absence, `active`/`_rev` absence, `flutter analyze`) is a source/CLI check, not test-based -- all run for real and all pass (see Accomplishments above).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `GymStateRepository` (`lib/core/data/gym_state_repository.dart`) is ready for Phase 2's Bloc layer to read/write the whole local profile through `importState`/`exportState`/`loadState`/`saveState` -- no later code should hand-roll SQL against `user_state`/`workouts`/`routines`/`bodyweight`.
- The indexed `workouts.d`/`workouts.id`/`bodyweight.d` columns are ready for Phase 3's History/Stats views to query directly without deserializing the whole profile.
- `AppDatabase.defaultPath()` is the standing on-device path for the real app; only a throwaway verification script should ever pass a different (in-memory/ffi) `path`/`factory` pair.
- No blockers for later Phase 1 plans (01-07 is the only plan remaining).

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: lib/core/db/schema.dart
- FOUND: lib/core/db/app_database.dart
- FOUND: lib/core/data/gym_state_repository.dart
- FOUND: .planning/phases/01-foundation-models/01-06-SUMMARY.md
- FOUND commit: 9432d14 (Task 1 commit)
- FOUND commit: e52ef80 (Task 2 commit)
