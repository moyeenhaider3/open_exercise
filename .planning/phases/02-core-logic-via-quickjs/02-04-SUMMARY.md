# Phase 2 Plan 04 Summary: Plain-Node Parity Oracle & Fixtures

## Outcome
Implemented the plain-Node parity oracle generator (`tool/js/gen-fixtures.mjs`), bridge inventory definition (`tool/js/bridge-inventory.mjs`), test case suites across all 7 module domains (`tool/js/fixture-cases/*.mjs`), the reproducible wrapper script with 3-timezone determinism validation (`tool/gen_js_fixtures.sh`), and the generated Dart fixtures embedding (`tool/parity/parity_fixtures_data.dart`).

## Parity Fixtures Summary
- **Source SHA-256 (`sourceSha256`):** `2190ad561541aa09fc6745b92f1e0ff78063a58ad544c3d3c5eb0c36acc21dad`
  (Matches `third_party/opengym/lib/MANIFEST.sha256` and bundle `__openGymLibMeta.sourceSha256`)
- **openGym Version:** `1.3.8`

### Breakdown by Module
| Module | Total Cases | Vitest Cross-Checked | Notes |
|---|---|---|---|
| `onerm` | 20 | 20 | All formulas, boundary rep cap, series, records |
| `bar` | 22 | 22 | Equipment checks, plate splits, no-bar / override logic |
| `workout-model` | 34 | 34 | phaseForSet edge cases, drop-set / rest-pause volumes, side-set sync |
| `progression` | 35 | 27 | Policies, increments, stall counting, Epley deload targets, prescriptions |
| `recovery` | 14 | 7 | Half-life decay, fixed-epoch stimulus, fatigued/detrained sets |
| `history` | 32 | 31 | Volume aggregations, set counts, mode detection, effort steps |
| `session` | 10 | 6 | Session entry generation, deduplication, name derivations |
| **Total** | **167** | **147** | **100% automated & timezone-independent** |

## Determinism & Verification
- `tool/gen_js_fixtures.sh` verifies byte-for-byte identical output under `TZ=UTC`, `TZ=Asia/Kolkata`, and `TZ=America/Los_Angeles`.
- No reliance on wall clock (`history.streakWeeks` excluded; fixed epoch timestamps used for recovery).
- `flutter analyze` is completely clean on `tool/parity/parity_fixtures_data.dart`.

## Artifacts Created & Modified
- `tool/js/bridge-inventory.mjs`: Central bridge inventory definition
- `tool/js/fixture-cases/helpers.mjs`: `UNDEF` symbol helper
- `tool/js/fixture-cases/onerm.mjs`: 20 cases
- `tool/js/fixture-cases/bar.mjs`: 22 cases
- `tool/js/fixture-cases/workout-model.mjs`: 34 cases
- `tool/js/fixture-cases/progression.mjs`: 35 cases
- `tool/js/fixture-cases/recovery.mjs`: 14 cases
- `tool/js/fixture-cases/history.mjs`: 32 cases
- `tool/js/fixture-cases/session.mjs`: 10 cases
- `tool/js/gen-fixtures.mjs`: ESM generator script with `assert.deepStrictEqual` vitest verification
- `tool/gen_js_fixtures.sh`: Executable generation & 3-timezone gate script
- `tool/fixtures/js-parity/*.json`: 7 JSON fixture files
- `tool/parity/parity_fixtures_data.dart`: Base64-chunked embedded fixtures for device harness
