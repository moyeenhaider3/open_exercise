---
phase: 1
slug: foundation-models
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-25
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + `bloc_test`, `mocktail`, `sqflite_common_ffi` (dev) |
| **Config file** | none — Wave 0 installs dev-dependencies |
| **Quick run command** | `flutter analyze && flutter test <changed-area>` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && flutter test <changed-area>`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01 | 1 | FND-01 | T-1-SC | Human legitimacy gate before any pub add | checkpoint (blocking-human) | n/a (human) | n/a | ⬜ pending |
| 01-01-T2 | 01 | 1 | FND-01 | T-1-SC, T-1-05 | Lockfile committed; AGPL LICENSE verbatim | smoke | `flutter pub get && flutter analyze && flutter test` | ✅ existing | ⬜ pending |
| 01-02-T1 | 02 | 2 | FND-02 | T-1-SC, T-1-06 | Codegen packages + JDK gated by user | checkpoint (blocking-human) | n/a (human) | n/a | ⬜ pending |
| 01-02-T2 | 02 | 2 | FND-02 | T-1-SC | Spike isolated in scratch dir | spike evidence | `grep -c "Decision: PENDING" 01-CODEGEN-SPIKE.md && git diff --quiet -- pubspec.yaml lib test` | ❌ W0 (created by task) | ⬜ pending |
| 01-02-T3 | 02 | 2 | FND-02 | — | N/A | checkpoint (decision) | `grep -E "^Decision: option-" 01-CODEGEN-SPIKE.md` | ❌ W0 | ⬜ pending |
| 01-03-T1 | 03 | 2 | FND-03 | T-1-04 | Fixture fully synthetic, deterministic | fixture check | `node tool/fixtures/gen_state_fixture.mjs && node -e "<marker check>"` | ❌ W0 (created by task) | ⬜ pending |
| 01-03-T2 | 03 | 2 | FND-03 | T-1-02 | `is`-check parsing, no `as` casts, garbage input never throws | unit (tdd) | `flutter test test/core/models/workout_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-T1 | 04 | 3 | FND-03 | T-1-02 | Defensive fromJson on part models | unit (tdd) | `flutter test test/core/models/state_parts_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-T2 | 04 | 3 | FND-03 | T-1-02, T-1-07 | Unknown keys kept at every level | unit (tdd) | `flutter test test/core/models/` | ❌ W0 | ⬜ pending |
| 01-05-T1 | 05 | 3 | FND-02 | T-1-SC | Generated output committed and reproducible | compile | `bash tool/gen_api.sh && flutter analyze` | ❌ W0 | ⬜ pending |
| 01-05-T2 | 05 | 3 | FND-02 | T-1-02 | State blob kept as raw Map | compile + mock-Dio coverage (30 ops) | `flutter test test/core/api/` | ❌ W0 | ⬜ pending |
| 01-06-T1 | 06 | 4 | FND-04 | — | N/A | integration (ffi) | `flutter test test/core/db/schema_test.dart` | ❌ W0 | ⬜ pending |
| 01-06-T2 | 06 | 4 | FND-04 | T-1-01, T-1-10 | Parameterized sqflite helpers only; transactional import | integration (ffi) | `flutter test test/core/db/round_trip_test.dart` | ❌ W0 | ⬜ pending |
| 01-07-T1 | 07 | 5 | FND-01, FND-05 | T-1-12 | Unknown theme/accent and load errors fall back to defaults | unit (bloc_test) | `flutter test test/features/shell/bloc/` | ❌ W0 | ⬜ pending |
| 01-07-T2 | 07 | 5 | FND-05 | — | N/A | compile | `flutter analyze` | n/a | ⬜ pending |
| 01-07-T3 | 07 | 5 | FND-01, FND-05 | T-1-13 | SPDX header enforced on lib/ files | widget + architecture | `flutter test test/features/shell/view/ test/architecture/ && flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs: `{phase}-{plan}-T{n}`. Filled in by the planner.*

---

## Wave 0 Requirements

- [ ] `flutter pub add --dev sqflite_common_ffi bloc_test mocktail yaml` (01-01-T2, after 01-01-T1 gate)
- [ ] `test/fixtures/state_sample.json` (01-03-T1) — synthesized from `../openGym/frontend/src/lib/demoSeed.js` + hand-augmented (dropset, restpause, superset, equipProfiles, gymCards)
- [ ] `test/core/db/round_trip_test.dart` — FND-04 (01-06-T2)
- [ ] `test/core/models/gym_state_test.dart` — FND-03 (01-04-T2; workout_test.dart in 01-03-T2)
- [ ] `test/core/api/` coverage + passthrough tests — FND-02 (01-05-T2)
- [ ] `test/features/shell/` + `test/architecture/layout_test.dart` — FND-01 / FND-05 (01-07-T1, 01-07-T3)
- [ ] OpenAPI generator spike (01-02-T2/T3) — pick generator that parses `../openGym/api/openapi.yaml` cleanly

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App boots to themed shell on a device/emulator | FND-05 | Real platform launch not covered by widget test | `flutter run` on Android + iOS simulator; confirm empty Material 3 shell renders |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
