---
phase: 01-foundation-models
plan: 01
subsystem: infra
tags: [flutter_bloc, equatable, sqflite, dio, go_router, path_provider, agpl, license, analyzer]

# Dependency graph
requires: []
provides:
  - Phase 1 core runtime dependency set (flutter_bloc, equatable, sqflite, dio, go_router, path_provider, path, collection) installed and resolved
  - AGPL-3.0-or-later LICENSE (copied verbatim from openGym) and NOTICE.md derivative-work attribution
  - Strict analyzer settings (strict-casts, strict-raw-types) and extra linter rules for all later plans
affects: [01-02, 01-03, 01-04, 01-05, 01-06, 01-07]

# Tech tracking
tech-stack:
  added: [flutter_bloc ^9.1.1, equatable ^3.0.0, sqflite ^2.4.4, dio ^5.11.1, go_router ^18.0.1, path_provider ^2.1.6, path ^1.9.1, collection ^1.19.1]
  patterns: ["SPDX-License-Identifier header on lib/ Dart files", "strict-casts/strict-raw-types analyzer mode", "no-tests project rule verified via flutter analyze + grep/cmp instead of flutter test"]

key-files:
  created: [LICENSE, NOTICE.md]
  modified: [pubspec.yaml, pubspec.lock, analysis_options.yaml, README.md, lib/main.dart]

key-decisions:
  - "User approved all 8 runtime packages (flutter_bloc, equatable, sqflite, dio, go_router, path_provider, path, collection) in the Task 1 legitimacy checkpoint"
  - "Dev-only packages from the plan (sqflite_common_ffi, bloc_test, mocktail, yaml) were NOT installed, per the project's mandatory no-tests rule"
  - "flutter test was not run (no-tests rule); flutter analyze plus grep/cmp assertions substituted for all test-based acceptance criteria"
  - "test/widget_test.dart was left untouched (SPDX header not added) since the no-tests rule and PreToolUse hook forbid writes under test/"

patterns-established:
  - "Every new lib/ Dart file must start with // SPDX-License-Identifier: AGPL-3.0-or-later"
  - "analysis_options.yaml now excludes lib/**/*.g.dart and lib/core/api/generated/** in preparation for Plan 01-02 codegen"

requirements-completed: [FND-01]

# Metrics
duration: ~10min
completed: 2026-09-25
---

# Phase 1 Plan 01: Foundation Dependencies & Licensing Summary

**Installed the approved Phase 1 core dependency set (flutter_bloc, equatable, sqflite, dio, go_router, path_provider, path, collection), added AGPL-3.0-or-later licensing/attribution copied from openGym, and tightened analyzer settings (strict-casts, strict-raw-types) ahead of later codegen and model plans.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-09-25T07:46:55Z
- **Tasks:** 2 (Task 1 pre-resolved by orchestrator; Task 2 executed)
- **Files modified:** 7 (pubspec.yaml, pubspec.lock, analysis_options.yaml, README.md, lib/main.dart, LICENSE (new), NOTICE.md (new))

## Accomplishments
- Phase 1 runtime dependency set installed and resolved (`flutter pub get` clean, `flutter analyze` reports "No issues found!")
- AGPL-3.0-or-later LICENSE copied byte-for-byte from `../openGym/LICENSE`; verified with `cmp`
- NOTICE.md created recording derivative-work status, SPDX header convention, and pointing to openGym's own third-party notices (MuscleMap, ExerciseDB dataset, QR/barcode libs) which continue to apply unchanged to the ported JS logic
- analysis_options.yaml tightened: `strict-casts: true`, `strict-raw-types: true`, excludes for future `.g.dart`/generated API code, plus `prefer_final_locals`, `avoid_dynamic_calls`, `always_declare_return_types` linter rules
- README.md replaced with project description, license/notice links, and `flutter analyze` as the verification command (no automated tests in this project)

## Task Commits

Each task was committed atomically:

1. **Task 1: Package legitimacy check** — pre-resolved by orchestrator (no commit; see "Checkpoint Resolution" below)
2. **Task 2: Install approved dependencies, add AGPL license and attribution, tighten analyzer** - `60b5b85` (feat)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP update)

## Checkpoint Resolution (Task 1)

Task 1 was a `checkpoint:human-verify` (`gate="blocking-human"`) package-legitimacy gate. It was already resolved by the orchestrator with the user before this executor started:

- **Approved (8):** flutter_bloc, equatable, sqflite, dio, go_router, path_provider, path, collection
- **Not installed (4, dev-only, per no-tests rule):** sqflite_common_ffi, bloc_test, mocktail, yaml — these were part of the plan's Task 1 package list but are excluded under the project's mandatory no-tests rule (CLAUDE.md, STATE.md decision log), so they were never presented for approval as installs and were skipped in Task 2's dependency-add step.

No packages were rejected by the user; the full runtime set was approved as-is.

## Files Created/Modified
- `LICENSE` - AGPL-3.0-or-later license text, copied verbatim from `../openGym/LICENSE`
- `NOTICE.md` - Derivative-work attribution to openGym, SPDX header convention, pointer to openGym's own third-party notices
- `pubspec.yaml` - Added flutter_bloc, equatable, sqflite, dio, go_router, path_provider, path, collection; updated description
- `pubspec.lock` - Resolved versions for the 8 new direct dependencies and their transitives
- `analysis_options.yaml` - strict-casts, strict-raw-types, future codegen excludes, 3 additional linter rules
- `README.md` - Project description, LICENSE/NOTICE.md links, flutter analyze as verify command
- `lib/main.dart` - Added `// SPDX-License-Identifier: AGPL-3.0-or-later` header line

## Decisions Made
- Followed the plan's Task 2 dependency list exactly for runtime packages (8/8 approved, all installed)
- Deviated from the plan's dev-dependency step (sqflite_common_ffi, bloc_test, mocktail, yaml) per the project's no-tests rule, which takes precedence per CLAUDE.md and the recorded STATE.md decision
- Did not add an SPDX header to `test/widget_test.dart` (plan asked for it) — a PreToolUse hook blocks writes to test paths, and the no-tests rule instructs executors to skip all test-file edits

## Deviations from Plan

### Auto-fixed / Rule-driven adjustments

**1. [No-tests project rule, CLAUDE.md precedence] Skipped dev-dependency install**
- **Found during:** Task 2 (dependency install step)
- **Issue:** Plan's action step calls for `flutter pub add --dev sqflite_common_ffi bloc_test mocktail yaml`. These are test-only tooling packages, forbidden by the project's mandatory no-tests rule.
- **Fix:** Did not run the dev-add command. Only the 8 runtime packages were installed.
- **Files modified:** pubspec.yaml, pubspec.lock (runtime deps only)
- **Verification:** `grep -cE "^  (sqflite_common_ffi|bloc_test|mocktail|yaml):" pubspec.yaml` returns 0, matching the intentional non-install
- **Committed in:** 60b5b85 (Task 2 commit)

**2. [No-tests project rule] Substituted flutter analyze for flutter test in verification**
- **Found during:** Task 2 (verify step)
- **Issue:** Plan's `<verify>` and acceptance criteria call for `flutter test` to exit 0.
- **Fix:** Ran `flutter pub get && flutter analyze` only. `flutter analyze` reports "No issues found!". `flutter test` was not run.
- **Files modified:** none (verification-only substitution)
- **Verification:** `flutter analyze` exit 0, confirmed by direct run
- **Committed in:** N/A (verification step, not a code change)

**3. [No-tests project rule] Did not add SPDX header to test/widget_test.dart**
- **Found during:** Task 2 (action step)
- **Issue:** Plan's action step calls for adding the SPDX header line to `test/widget_test.dart` in addition to `lib/main.dart`.
- **Fix:** Only `lib/main.dart` was updated. `test/widget_test.dart` was left untouched (a PreToolUse hook blocks writes to test paths per project rule).
- **Files modified:** lib/main.dart only
- **Verification:** `head -1 lib/main.dart` equals `// SPDX-License-Identifier: AGPL-3.0-or-later`
- **Committed in:** 60b5b85 (Task 2 commit)

---

**Total deviations:** 3, all driven by the project's mandatory no-tests rule (CLAUDE.md/STATE.md), not ad-hoc executor judgment.
**Impact on plan:** No scope creep — deviations are subtractive (skipping test-related plan content) per an explicit, pre-existing project constraint that overrides plan instructions where they conflict.

## Issues Encountered
None beyond the no-tests rule substitutions documented above.

## Skipped Acceptance Criteria (no-tests rule, not failures)
- `grep -E "^  (sqflite_common_ffi|bloc_test|mocktail|yaml):" pubspec.yaml returns 4 lines` — N/A, these packages are intentionally not installed; the equivalent check (0 lines) was verified instead.
- `flutter test exits 0` — N/A, no automated tests in this project; `flutter analyze` (exit 0) was used as the substitute verification.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 1 core dependency set is in place; Plan 01-02 (OpenAPI codegen dependency gate) and Plan 01-03 (hand-written state models) can build on flutter_bloc/equatable/sqflite/dio directly.
- LICENSE and NOTICE.md are established as the canonical attribution files; later plans that vendor openGym assets (e.g. Plan 01-05's openapi.yaml snapshot) should reference NOTICE.md's "keep original notices" rule rather than re-deriving licensing text.
- analysis_options.yaml already excludes `lib/**/*.g.dart` and `lib/core/api/generated/**`, so Plan 01-02's codegen output will not need a follow-up analyzer config change.
- No blockers.

---
*Phase: 01-foundation-models*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: LICENSE
- FOUND: NOTICE.md
- FOUND: .planning/phases/01-foundation-models/01-01-SUMMARY.md
- FOUND commit: 60b5b85 (Task 2 feat commit)
- FOUND commit: a52534e (SUMMARY docs commit)
