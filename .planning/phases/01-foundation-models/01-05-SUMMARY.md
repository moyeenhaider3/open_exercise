---
phase: 01-foundation-models
plan: 05
subsystem: api
tags: [openapi, codegen, dio, retrofit, dart, json_serializable]

# Dependency graph
requires:
  - phase: 01-foundation-models (Plan 01-01)
    provides: Phase 1 core dependency set (dio, etc.) and analysis_options.yaml exclusion for lib/core/api/generated/**
  - phase: 01-foundation-models (Plan 01-02)
    provides: "Decision: option-retrofit (openapi_retrofit_generator 2.0.4, plain spec, no preprocessing) and the closed-`State`-class finding this plan's wrapper works around"
provides:
  - "Vendored third_party/opengym/openapi.yaml + README.md provenance record"
  - "tool/gen_api.sh: reproducible codegen script (--sync, generate, build_runner, dart format)"
  - "lib/core/api/generated/: 7 rest clients (meta, auth, pairing, data, push, activity, admin), 30 requests, 66 data classes"
  - "lib/core/api/open_gym_api_client.dart: ApiClientFactory + OpenGymApiClient wrapping every generated API group, with fetchState()/pushState() convenience methods that keep /api/data's state payload a raw Map"
affects: [01-06, 01-07, "Phase 5 (auth/session wiring uses the `dio` getter reserved here)"]

# Tech tracking
tech-stack:
  added: [retrofit ^4.10.0, json_annotation ^4.12.0, "openapi_retrofit_generator ^2.0.4 (dev)", "retrofit_generator ^10.2.11 (dev)", "json_serializable ^6.14.1 (dev)", "build_runner ^2.16.1 (dev)"]
  patterns:
    - "OpenAPI -> Dio client codegen via tool/gen_api.sh (option-retrofit: openapi_retrofit_generator, pure Dart, no JVM), output committed under lib/core/api/generated/ (excluded from flutter analyze)"
    - "Closed generated schema classes (e.g. State) are bypassed for round-tripping: hand-authored wrapper methods read/write the raw Dio response/request body as Map<String, Object?> instead of the generated typed class"

key-files:
  created:
    - third_party/opengym/openapi.yaml
    - third_party/opengym/README.md
    - openapi_generator.yaml
    - tool/gen_api.sh
    - lib/core/api/generated/** (142 files: rest_client.dart, 7 *_client.dart + *_client.g.dart pairs, 66 model *.dart + matching *.g.dart)
    - lib/core/api/open_gym_api_client.dart
  modified:
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Followed 01-CODEGEN-SPIKE.md's option-retrofit branch exactly: openapi_retrofit_generator 2.0.4 against the plain unmodified spec, no preprocessing step in tool/gen_api.sh."
  - "No generator-level fixup was applied for the closed `State` class (Task 1's conditional fixup instruction did not apply — the spike found none was needed/available). Instead, per the spike's own guidance, OpenGymApiClient.fetchState()/pushState() bypass DataClient.getData()/putData() entirely and talk to GET/PUT /api/data directly through the same Dio instance, decoding the response/building the request body as a plain Map so unknown state keys survive."
  - "../openGym is not a git repository on this machine, so the plan's `git -C ../openGym rev-parse HEAD` provenance step could not run. third_party/opengym/README.md records a SHA-256 content hash and source mtime instead, with the exact command that failed documented as evidence."
  - "Per the project's mandatory no-tests rule (CLAUDE.md, STATE.md), test/core/api/api_coverage_test.dart and test/core/api/data_state_passthrough_test.dart were not created. Verification substituted grep/CLI assertions: 30 @GET/@POST/@PUT annotations across the 7 generated *_client.dart files were counted and matched 1:1 against the 30 GET/PUT/POST method+path pairs enumerated directly from third_party/opengym/openapi.yaml (29 paths; /api/data has both GET and PUT)."

patterns-established:
  - "tool/gen_api.sh is the single reproducible entry point for all future openapi.yaml changes: --sync re-copies the spec from ../openGym, then regenerates + formats lib/core/api/generated/. Verified reproducible by running it twice and diffing the output tree (identical)."
  - "Generated closed-class schemas (json_serializable, no additionalProperties: true) must never be used to round-trip a 'representative, not enforced' spec schema — a parallel Map-backed read/write path is required, mirrored here for /api/data exactly as Plans 01-03/01-04 do for local GymState."

requirements-completed: [FND-02]

# Metrics
duration: ~15min
completed: 2026-09-25
---

# Phase 1 Plan 05: OpenAPI Codegen & Dio Client Wrapper Summary

**Generated Dio/Retrofit clients for all 30 openGym API operations via `openapi_retrofit_generator` 2.0.4 (the option-retrofit decision from Plan 01-02), wrapped them in `OpenGymApiClient`, and kept `/api/data`'s `state` payload a raw, unknown-key-preserving `Map` by bypassing the generated closed `State` class entirely.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-09-25T09:16:00Z (approx.)
- **Completed:** 2026-09-25T09:31:36Z
- **Tasks:** 2 (both `type="auto"`; Task 2's `tdd="true"` test steps skipped per no-tests rule)
- **Files modified:** 5 tracked paths modified/created outside `lib/core/api/generated/` (third_party/opengym/openapi.yaml, third_party/opengym/README.md, openapi_generator.yaml, tool/gen_api.sh, lib/core/api/open_gym_api_client.dart) + pubspec.yaml/pubspec.lock, plus 142 generated files under `lib/core/api/generated/`

## Accomplishments
- Vendored `third_party/opengym/openapi.yaml` byte-identical to `../openGym/api/openapi.yaml` (confirmed via `cmp`), with a README.md recording provenance and the `--sync` refresh workflow
- Wrote `tool/gen_api.sh`, confirmed reproducible: running it twice back-to-back produces a byte-identical `lib/core/api/generated/` tree (`diff -rq` empty)
- Generated 7 rest clients / 30 requests / 66 data classes from the vendored spec via `openapi_retrofit_generator` 2.0.4 + `build_runner` 2.16.1 + `json_serializable` 6.14.1 — matches the Plan 01-02 spike's numbers exactly
- Confirmed the spike's closed-`State`-class finding in the real app tree: `GetDataResponse.state` is `State?` (declared-properties-only), `PutDataRequest.state` is a required non-nullable `State` — neither can safely carry arbitrary state keys
- Built `lib/core/api/open_gym_api_client.dart`: `ApiClientFactory.create({baseUrl, dio, adapter})` + `OpenGymApiClient` exposing all 7 generated API groups (`meta`, `auth`, `pairing`, `data`, `push`, `activity`, `admin`) plus `fetchState()`/`pushState()` that read/write `/api/data` as a raw `Map` via the same `Dio` instance
- `flutter analyze` clean throughout (generated code already excluded via Plan 01-01's `analysis_options.yaml`)

## Task Commits

Each task was committed atomically:

1. **Task 1: Vendor the spec, write tool/gen_api.sh and generate the clients using the decided option** - `2d23c41` (feat)
2. **Task 2: OpenGymApiClient wrapper plus spec-driven coverage and state-passthrough tests** - `22e97e4` (feat) — test-file portion skipped per no-tests rule (see Deviations)

**Plan metadata:** (this commit, made by this executor after the SUMMARY self-check)

## Files Created/Modified
- `third_party/opengym/openapi.yaml` - Byte-for-byte vendored copy of `../openGym/api/openapi.yaml` (OpenAPI 3.1.0, 1536 lines)
- `third_party/opengym/README.md` - Provenance (SHA-256 + source mtime, since `../openGym` has no git history), license note, `--sync` refresh instructions
- `openapi_generator.yaml` - `openapi_retrofit_generator` config: `schema_path: third_party/opengym/openapi.yaml`, `output_directory: lib/core/api/generated`, `json_serializer: json_serializable`
- `tool/gen_api.sh` - Reproducible codegen script: optional `--sync` (re-copy spec from `../openGym`), `dart run openapi_retrofit_generator`, `dart run build_runner build --delete-conflicting-outputs`, `dart format lib/core/api/generated`
- `lib/core/api/generated/**` - 142 generated files: `rest_client.dart` (aggregates all 7 groups), 7×(`*_client.dart` + `*_client.g.dart`), 66×(model `.dart` + matching `.g.dart` where applicable)
- `lib/core/api/open_gym_api_client.dart` - `ApiClientFactory` + `OpenGymApiClient` wrapper; `fetchState()`/`pushState()` convenience methods over `/api/data`
- `pubspec.yaml` / `pubspec.lock` - Added `retrofit ^4.10.0`, `json_annotation ^4.12.0` (deps); `openapi_retrofit_generator ^2.0.4`, `retrofit_generator ^10.2.11`, `json_serializable ^6.14.1`, `build_runner ^2.16.1` (dev deps) — all versions pinned to match the Plan 01-02 spike exactly

## Decisions Made
- Followed `Decision: option-retrofit` from `01-CODEGEN-SPIKE.md` verbatim: plain spec, no preprocessing, `openapi_retrofit_generator` 2.0.4.
- Did not apply Task 1's conditional "generator-level fixup for the closed State class" instruction — the spike explicitly found no such fixup existed/was needed for this generator version. Instead followed the spike's own recommended mitigation: `OpenGymApiClient` bypasses `DataClient.getData()`/`putData()` and talks to `/api/data` directly through the shared `Dio` instance, decoding/encoding the `state` field as a plain `Map<String, Object?>`.
- Recorded vendor provenance by content hash + mtime instead of a git commit hash, since `../openGym` is not a git repository on this machine.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] `../openGym` has no git history for spec provenance**
- **Found during:** Task 1 (vendoring the spec)
- **Issue:** The plan's action step calls for `git -C ../openGym rev-parse HEAD` to record the source commit in `third_party/opengym/README.md`. `../openGym` is a plain directory, not a git repository (`git -C ../openGym rev-parse HEAD` fails with "fatal: not a git repository").
- **Fix:** Recorded a SHA-256 content hash (`shasum -a 256`) and the source file's mtime instead, plus the exact failing command as evidence, in `third_party/opengym/README.md`.
- **Files modified:** `third_party/opengym/README.md`
- **Verification:** `shasum -a 256 ../openGym/api/openapi.yaml` matches the hash recorded in the README; `cmp third_party/opengym/openapi.yaml ../openGym/api/openapi.yaml` exits 0
- **Committed in:** `2d23c41` (Task 1 commit)

**2. [Rule 3 - Blocking issue, necessary supporting file not in plan's files_modified list] Added `openapi_generator.yaml`**
- **Found during:** Task 1 (configuring the generator)
- **Issue:** `openapi_retrofit_generator` requires a root-level `openapi_generator.yaml` config file (schema_path/output_directory/json_serializer) to run at all; the plan's `files_modified` frontmatter list doesn't mention it, but Task 1's action step implicitly requires "configure it to emit into lib/core/api/generated/."
- **Fix:** Added `openapi_generator.yaml` at the repo root, matching the Plan 01-02 spike's working config exactly (`schema_path: third_party/opengym/openapi.yaml`, `output_directory: lib/core/api/generated`, `json_serializer: json_serializable`).
- **Files modified:** `openapi_generator.yaml` (new)
- **Verification:** `dart run openapi_retrofit_generator` succeeds and reports "30 requests, 66 data classes" matching the spike
- **Committed in:** `2d23c41` (Task 1 commit)

### Deferred to no-tests rule (not failures)

**3. [Project no-tests rule, CLAUDE.md/STATE.md precedence] Skipped `test/core/api/api_coverage_test.dart` and `test/core/api/data_state_passthrough_test.dart`**
- **Found during:** Task 2
- **Issue:** Task 2 is `tdd="true"` and calls for a spec-driven coverage test and a state-passthrough test under `test/core/api/`.
- **Fix:** Did not create either test file (a PreToolUse hook also blocks writes under `test/`). Substituted grep/CLI verification per the project's mandatory no-tests rule: counted `@GET/@POST/@PUT` annotations across the 7 generated `*_client.dart` files (30) and cross-checked against the 30 method+path pairs read directly out of `third_party/opengym/openapi.yaml` (29 paths, `/api/data` has both GET and PUT) — exact 1:1 match, no missing/extra operations.
- **Files modified:** none (verification-only substitution)
- **Verification:** see counts above; `flutter analyze` exit 0
- **Committed in:** `22e97e4` (Task 2 commit, code-only; no test commit exists)

## Issues Encountered
None beyond the no-tests rule substitutions and the missing-git-history provenance workaround documented above.

## Skipped Acceptance Criteria (no-tests rule, not failures)
- `flutter test test/core/api/ exits 0` — N/A, no automated tests in this project. Substituted `flutter analyze` (exit 0) plus the grep/CLI operation-count cross-check described in Deviation 3.
- `grep -c "loadYaml" test/core/api/api_coverage_test.dart returns at least 1` — N/A, that test file was not created. The equivalent spec-vs-generated-code cross-check was performed via shell `grep`/`awk` directly against `third_party/opengym/openapi.yaml` instead of `package:yaml` inside a test.

## User Setup Required
None - no external service configuration required. No JVM is installed or needed (option-retrofit is pure Dart, per the Plan 01-02 spike).

## Next Phase Readiness
- `OpenGymApiClient` is ready for Plan 01-06/01-07 to consume for any read/write against the openGym API surface.
- `OpenGymApiClient.dio` is exposed specifically so Phase 5 can attach cookie/bearer/CSRF interceptors without touching this wrapper's construction logic.
- `fetchState()`/`pushState()` are the only supported way to read/write `/api/data`'s `state` blob from this client — callers must not reach for `data.getData()`/`data.putData()` directly if they need the `state` field, since those route through the closed generated `State` class.
- `tool/gen_api.sh --sync` is the standing procedure for any future openGym API spec change.
- No blockers for later Phase 1 plans.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: third_party/opengym/openapi.yaml
- FOUND: third_party/opengym/README.md
- FOUND: openapi_generator.yaml
- FOUND: tool/gen_api.sh
- FOUND: lib/core/api/generated/rest_client.dart
- FOUND: lib/core/api/open_gym_api_client.dart
- FOUND commit: 2d23c41 (Task 1)
- FOUND commit: 22e97e4 (Task 2)
