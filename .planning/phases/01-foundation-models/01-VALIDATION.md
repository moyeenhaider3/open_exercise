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
| 1-xx | TBD | TBD | FND-01 | — | N/A | unit (bloc_test) | `flutter test test/features/shell/bloc/` | ❌ W0 | ⬜ pending |
| 1-xx | TBD | TBD | FND-02 | — | N/A | compile + mock-Dio smoke | `flutter analyze && flutter test test/core/api/` | ❌ W0 | ⬜ pending |
| 1-xx | TBD | TBD | FND-03 | T-1-02 | Defensive fromJson, no force-casts | unit | `flutter test test/core/models/gym_state_test.dart` | ❌ W0 | ⬜ pending |
| 1-xx | TBD | TBD | FND-04 | T-1-01 | Parameterized sqflite queries only | integration (ffi) | `flutter test test/core/db/round_trip_test.dart` | ❌ W0 | ⬜ pending |
| 1-xx | TBD | TBD | FND-05 | — | N/A | widget | `flutter test test/features/shell/view/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs are filled in by the planner.*

---

## Wave 0 Requirements

- [ ] `flutter pub add --dev sqflite_common_ffi bloc_test mocktail`
- [ ] `test/fixtures/state_sample.json` — synthesized from `../openGym/frontend/src/lib/demoSeed.js` + hand-augmented (dropset, restpause, superset, equipProfiles, gymCards)
- [ ] `test/core/db/round_trip_test.dart` — FND-04
- [ ] `test/core/models/gym_state_test.dart` — FND-03
- [ ] `test/core/api/` smoke tests — FND-02
- [ ] `test/features/shell/` — FND-01 / FND-05
- [ ] OpenAPI generator spike — pick generator that parses `../openGym/api/openapi.yaml` cleanly

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
