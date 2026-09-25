---
phase: 01-foundation-models
verified: 2026-09-25
status: human_needed
score: 24/28 must-haves verified (4 test-based truths substituted per the no-tests rule, 0 failed)
requirements: [FND-01, FND-02, FND-03, FND-04, FND-05]
requirements_satisfied: 5/5 (FND-04 on substituted evidence)
success_criteria: 2/4 fully met, 2/4 met on substituted verification (SC#3, SC#4)
gaps: []
advisory:
  - CR-01 (ShellBloc fallback save can wipe profile) - does not defeat a Phase 1 truth; fix before Phase 3 writes through the repository
  - CR-03 (concurrent read-modify-write in ShellBloc) - same classification
  - CR-02 (SetEntry.resolvedPhase != phaseForSet) - not a Phase 1 truth; resolve via JS bridge in Phase 2 (JS-04)
human_verification:
  - Accept substituted verification for SC#3 (FND-04 round-trip) and SC#4 (flutter test)
  - Optionally confirm the app boots to the empty dark shell on your own device
  - Decide whether CR-01/CR-03 are fixed now (gsd-code-review --fix) or scheduled before Phase 3
---

# Phase 1: Foundation & Models - Verification

**Goal:** A typed, persisted data layer that can hold a real openGym state file and talk to every API route.

## Goal Achievement

The goal is achieved in the codebase:

- **Typed layer.** `GymState` has a typed field for all 38 `DEF` keys in `useStore.js`, checked by script. Passthrough `JsonReader` models keep unknown keys, nulls and wrong-typed values.
- **Persistence.** There is a hybrid sqflite schema v1 and a `GymStateRepository` with import, export, load and save.
- **API coverage.** Dio/Retrofit clients generated from the vendored spec cover all 30 operations on 29 paths. The generated set of paths is identical to the spec's.
- **Themed shell.** The app boots to it on a real Android emulator (screenshot inspected).
- **Analyzer.** `flutter analyze` is clean.

Two items cannot be met as written. The user's NO-TESTS rule is hook-enforced and there are no test files: `test/` does not exist.

- **SC#3:** "automated test" for the round trip.
- **SC#4:** `flutter test` passes.

Substitute verification was done instead, as described below. Status is `human_needed`, not `passed`, until the user accepts those substitutes. This is not `gaps_found`: the no-tests rule is a user decision.

## Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `lib/core/` and `lib/features/` exist, app boots to empty themed shell | MET | `lib/core/{api,data,db,models,router,theme}`, `lib/features/shell/{data,bloc,view}` exist. The `shell-boot.png` emulator screenshot (in the session scratchpad) shows a black `#000000` background, an AppBar titled "openGym" and an empty body |
| 2 | Generated models + Dio clients compile and cover every path in openapi.yaml | MET | The spec has 29 paths and 30 operations. The generated code has 30 unique `@GET/@POST/@PUT(...)` annotations, and its set of paths diffs as equal to the spec's. The vendored spec is byte-identical to `../openGym/api/openapi.yaml`. `flutter analyze` is clean. `OpenGymApiClient` exposes all 7 generated clients |
| 3 | Synthetic state json imports into sqflite and exports to equivalent JSON (automated test) | NOT MET AS WRITTEN, substituted | No automated test exists (no-tests rule). 01-06-SUMMARY reports a throwaway `dart run` script (outside the repo, `sqflite_common_ffi` in-memory) over the real `tool/fixtures/state_sample.json`: 9/9 cases passed, `DeepCollectionEquality` holds including `active`, `_ts`, `_rev` and `__futureTopLevel`. Those scratch scripts have since been deleted, so the verifier could not re-inspect them. The code paths were checked statically (see 01-06 below) |
| 4 | `flutter analyze` and `flutter test` pass | PARTIAL: analyze met, test not met as written | `flutter analyze`: "No issues found!" (the verifier ran it). `flutter test` was not run because there are no tests by user rule |

## Requirements Coverage

| ID | Plan(s) | Status | Evidence |
|----|---------|--------|----------|
| FND-01 | 01-01, 01-07 | SATISFIED | Feature-first layout exists. `flutter_bloc` and `equatable` are in pubspec. The only Bloc (`ShellBloc`) has `sealed class ShellState` and `sealed class ShellEvent` with `final` subclasses |
| FND-02 | 01-02, 01-05 | SATISFIED | `Decision: option-retrofit` in 01-CODEGEN-SPIKE.md. `tool/gen_api.sh` regenerates the clients. All 30 operations are covered: auth, pair, data, push, activity, admin and meta. `/api/data` is read and written as a raw Map |
| FND-03 | 01-03, 01-04 | SATISFIED | All 38 DEF keys are present in `kDefaultState`, `gym_state.dart` and the fixture. `SetEntry`, `DropEntry`, `ClusterEntry` and `SideSets` model phase/type, drops and clusters. The fixture contains restpause, drops, clusters, warmup, per-side (`L`), superset (`sg`), `null`s and `__futureTopLevel` |
| FND-04 | 01-06 | SATISFIED ON SUBSTITUTED EVIDENCE | The schema and repository exist with indexed `d` columns and parameter binding only. The round trip was verified by a throwaway script, not an automated test (see SC#3) |
| FND-05 | 01-07 | SATISFIED | `main.dart` runs `AppDatabase.open`, then `AppDependencies`, then `runApp`. `MultiRepositoryProvider` provides the repository and the `ApiClientFactory`. `MaterialApp.router(routerConfig:)` uses go_router. `buildAppTheme` is Material 3 with 8 accents; the default is dark + lime. The app boots on the emulator |

All 5 IDs from the plan frontmatter appear in REQUIREMENTS.md, and all are mapped to Phase 1. None are orphaned.

## Must-Haves (per plan)

### 01-01 (FND-01) - 2/3
| Truth / Artifact | Status |
|---|---|
| Deps installed only after user legitimacy approval | VERIFIED. 8 runtime packages are approved (SUMMARY) and the codegen dev packages were approved in 01-02. The test dev-deps were intentionally not installed |
| AGPL-3.0-or-later with openGym attribution | VERIFIED. `LICENSE` header is "GNU AFFERO GENERAL PUBLIC LICENSE". `NOTICE.md` has 2 matches for AGPL-3.0-or-later. Every hand-written lib file has an SPDX header (0 missing) |
| flutter analyze and flutter test pass | SUBSTITUTED. Analyze is clean; test is N/A under the no-tests rule |
| pubspec has flutter_bloc; analysis_options has strict-casts | VERIFIED |
| key_link pattern `sqflite_common_ffi` in pubspec | DEVIATION (accepted). Intentionally absent under the no-tests rule |

### 01-02 (FND-02) - 3/3
| Truth / Artifact | Status |
|---|---|
| Generator chosen by user from spike evidence | VERIFIED. `Decision: option-retrofit` at line 149 of 01-CODEGEN-SPIKE.md. Commits ee4f8ca and 8dee7d3 |
| Both candidates run, or the reason one could not run is recorded | VERIFIED. SUMMARY: the user declined the JDK install, so dart-dio could not run; the reason is recorded in the spike doc |
| No codegen package before legitimacy confirmation | VERIFIED (SUMMARY checkpoint record) |

### 01-03 (FND-03) - 4/4
| Truth / Artifact | Status |
|---|---|
| Fixture covers dropsets, rest-pause, warm-up, per-side, supersets, nulls, unknown keys, malformed value | VERIFIED by grep of `tool/fixtures/state_sample.json`, which has 32 workouts |
| Workout/WorkoutEntry/SetEntry re-emit identical JSON | VERIFIED statically: `JsonReader` is used in `workout.dart`. Runtime check comes from the SUMMARY's transient script. The code review confirmed the passthrough holds |
| Unknown keys, nulls and wrong types survive at every level | VERIFIED (review traced every reader type) |
| Malformed input never throws | VERIFIED (review and SUMMARY) |
| Artifact path `test/fixtures/state_sample.json` | DEVIATION (accepted). It is at `tool/fixtures/state_sample.json` because the hook blocks `test/`. `workout_test.dart` was not created |

### 01-04 (FND-03) - 4/4
| Truth / Artifact | Status |
|---|---|
| GymState types every DEF key | VERIFIED. A script compared the 38 DEF keys from `useStore.js` with `gym_state.dart` and `default_state.dart`; 0 were missing |
| fromJson overlays onto DEF | VERIFIED. `kDefaultState` is referenced in `gym_state.dart` |
| fromJson(fixture).toJson() deep-equals the fixture | VERIFIED by the SUMMARY's transient script |
| Part models round-trip | VERIFIED by the SUMMARY's transient script |
| `class GymState extends Equatable`; key links `Workout.fromJson` and `kDefaultState` | VERIFIED |

### 01-05 (FND-02) - 3/4
| Truth / Artifact | Status |
|---|---|
| Clients generated by one reproducible script | VERIFIED. `tool/gen_api.sh` with `--sync`. The SUMMARY reports two identical runs |
| A test proves all 30 operations | SUBSTITUTED. No test exists. The verifier ran a script that diffs the spec's 29 paths against the generated annotations: equal, 30 unique operations |
| GET /api/data returns an untyped Map | VERIFIED. `OpenGymApiClient.fetchState` and `pushState` use raw `Map<String, Object?>` |
| flutter analyze passes with generated code | VERIFIED. The generated code is excluded from analysis, and analyze is clean |
| Artifacts: vendored spec with `openapi: 3.1.0`, `class ApiClientFactory`, import of `generated/` | VERIFIED. `api_coverage_test.dart` is absent (no-tests rule) |

### 01-06 (FND-04) - 3/4
| Truth / Artifact | Status |
|---|---|
| Import then export deep-equals the fixture (automated test) | SUBSTITUTED. A throwaway ffi script reported 9/9 in the SUMMARY. No automated test exists |
| Array order, duplicate ids, active, _ts, _rev and unknown keys survive | VERIFIED. Statically: `(uid, pos)` rows ordered by `pos ASC`, `raw_json` per element, `_ts`/`_rev` columns, and tri-state `*_present` columns. Runtime check is in the SUMMARY |
| Indexed date column on workouts and bodyweight | VERIFIED. `idx_workouts_uid_d` and `idx_bodyweight_uid_d` exist |
| No user value interpolated into SQL | VERIFIED. There are no raw* calls. The only `execute` runs the constant CREATE statements. `where:` strings interpolate only column constants, and values go through `whereArgs` |
| Artifacts `CREATE TABLE workouts`, `class AppDatabase` (injectable factory), `class GymStateRepository`; key links `Tables.` and `GymState.fromJson` | VERIFIED. `round_trip_test.dart` is absent (no-tests rule) |

### 01-07 (FND-01, FND-05) - 5/6
| Truth / Artifact | Status |
|---|---|
| Boots to an empty Material 3 shell | VERIFIED. `ShellPage` is a Scaffold with an AppBar and `SizedBox.shrink`. The emulator screenshot was inspected |
| Theme follows stored state; defaults to dark + lime; 8 accents | VERIFIED. `kAccents` has 8 entries with lime `0xFF30D158`, and `ThemeSettings.defaults()` returns `ThemeMode.dark` with lime |
| Repository and ApiClientFactory provided via MultiRepositoryProvider | VERIFIED (`lib/app/app.dart`) |
| Routing through go_router | VERIFIED (`createAppRouter`, `routerConfig: _router`) |
| Layout exists; every Bloc has sealed State/Event | VERIFIED |
| flutter analyze and flutter test pass | SUBSTITUTED. Analyze is clean; test is N/A |
| Key links `loadState`/`saveState`, `routerConfig`, `buildAppTheme`; `main.dart` contains `AppDatabase.open` | VERIFIED |

**Totals:** 24 of 28 truths verified. 4 truths are substituted, all test-based: 01-01 #3, 01-05 #2, 01-06 #1 and 01-07 #6. None failed.

## Gaps

None block the phase goal.

### Code review Critical findings (01-REVIEW.md): assessed, not gaps

- **CR-01: ShellBloc fallback save can wipe the profile.** It only triggers when `loadState` throws and the user then changes theme or accent. It does not defeat any Phase 1 truth:
  - The repository round trip itself is correct.
  - The truth "theme follows stored state" holds on the normal path.
  - It is a real data-loss hazard in the persistence layer, so it is **strongly recommended to fix before Phase 3** starts writing workouts through the same repository.
- **CR-03: ShellBloc handlers run concurrently with whole-document read-modify-write.** Same classification. It is latent in Phase 1, where the only writers are two shell events. It becomes a lost-update bug once Phase 3 adds writers. Recommended fix: a sequential transformer plus targeted patch writes.
- **CR-02: `SetEntry.resolvedPhase` diverges from openGym's `phaseForSet`.** No Phase 1 truth depends on this getter, and nothing consumes it yet. It conflicts with the core value and with JS-04 (no hand-written domain logic). Delete it or route it through the JS bridge in Phase 2.

## Human Verification

1. **Accept the substituted verification for SC#3 and SC#4.**
   - What was done: FND-04's round trip was proven by a throwaway `sqflite_common_ffi` script over the real fixture (01-06, 9/9 passed). `flutter test` is replaced by `flutter analyze` plus grep/CLI checks, the verifier's diff of spec paths against generated paths, and the emulator boot.
   - Expected: the user confirms this satisfies SC#3 and SC#4 under the NO-TESTS rule. Otherwise the ROADMAP wording should be amended to drop "automated test" and "flutter test".
2. **Optional: confirm the app boots on your device.**
   - Run `flutter run` on an Android or iOS device.
   - Expected: a black background, an AppBar titled "openGym" and an empty body, with no crash on first launch. iOS has not been exercised; only an Android emulator was used.
3. **Decide how to handle CR-01 and CR-03.**
   - Options: fix now via `/gsd-code-review --fix` for Phase 1, or record them as a Phase 3 prerequisite.
   - Expected: an explicit decision is recorded in STATE.md.

## Evidence

```
$ flutter analyze
Analyzing open_exercise...
No issues found! (ran in 2.9s)

$ ls test
ls: test: No such file or directory          # intentional, no-tests rule
$ git ls-files | grep -iE "_test\.dart|tmp_verify|verify_task"
(none)

$ cmp third_party/opengym/openapi.yaml ../openGym/api/openapi.yaml && echo vendored==upstream
vendored==upstream
spec paths 29 ops 30
generated unique @METHOD('path') annotations: 30
diff <(sort spec paths) <(sort generated paths)  -> PATH SETS EQUAL

$ grep -n "Decision:" 01-CODEGEN-SPIKE.md
149:Decision: option-retrofit

DEF keys (useStore.js): 38
DEF missing in fixture: []   DEF missing in kDefaultState: []   DEF missing in gym_state.dart: []
fixture: 32 workouts; markers restpause=1 drops=2 clusters=1 warmup=2 sg=2 "L"=2 null=13 __futureTopLevel=1 _ts=1 _rev=1

$ grep -n "CREATE\|INDEX" lib/core/db/schema.dart
CREATE TABLE user_state / workouts / routines / bodyweight
idx_workouts_uid_d, idx_workouts_uid_id, idx_bodyweight_uid_d

$ grep -rn "rawQuery|rawInsert|rawUpdate|rawDelete|.execute(" lib (excl. generated)
lib/core/db/app_database.dart:34: batch.execute(statement);   # constant kCreateStatementsV1 only

SPDX header missing in hand-written lib/*.dart: (none)
sealed classes: shell_event.dart, shell_state.dart; Blocs: ShellBloc only

Commits claimed in SUMMARYs, all present:
60b5b85 a52534e ee4f8ca 8dee7d3 e0625dd 19e89ff 20725aa 99052ff 2d23c41 22e97e4 9432d14 e52ef80 91b6642 69d198a 68ec18d

Emulator screenshot (scratchpad/shell-boot.png, from 01-07 execution) inspected:
black body, dark AppBar "openGym", DEBUG banner, empty content.
Note: 01-06 scratch round-trip projects (scratchpad/roundtrip-check/task1, task2) were deleted after use; the verifier could not re-inspect them.
```
