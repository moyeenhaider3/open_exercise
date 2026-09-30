# Plan 04-01 Summary: Muscle Map JS Bridge Extensions, Shim & Parity Fixtures

## Executive Summary
Plan `04-01` extended the JS bridge with everything needed to shade, query, and explore the body muscle map on the JavaScript side, following the JS-04 parity architecture:
- **Vendored Modules**: Vendored `recovery-view.js` (`fatigueStateOf`) and `strength-exercises.js` (`strengthExerciseRowsForMuscle`) from `openGym` frontend into `third_party/opengym/lib/` without drift; updated `MANIFEST.sha256` and `VERSION`.
- **Muscle View Shim**: Created `tool/js/shims/muscle-view-shim.js` transcribing Stats and MuscleExplorer calculations from openGym verbatim:
  - `FATIGUE_LEVELS` and `STRENGTH_LEVELS` (using imported `STRENGTH_FLOOR`, not hardcoded values).
  - `muscleBalance(S, win, hard, nowMs, todayIso)`: Windowing, rated set detection, hard set filtering, muscle ranking, load, relative levels, top-4 percentages, and formatted set counts.
  - `fatigueView(S, nowMs)`: Fatigue calculation, absolute shade levels via `FATIGUE_LEVELS`, and semantic fatigue states via `fatigueStateOf`.
  - `strengthView(S, nowMs, sel)`: Strength calculations, absolute shade levels via `STRENGTH_LEVELS`, detrained list with 90-day volumes and weeks since training, and exercise rows for selected muscle.
  - `muscleIndex(S, ids)`: Batch exercise-to-muscle lookup.
- **Bundle Rebuild**: Rebuilt `assets/js/opengym-lib.bundle.js` with `esbuild 0.28.2`; verified input metafile audit with 32 allowed inputs.
- **Bridge Inventory & Parity Fixtures**: Registered 13 new functions across `muscles`, `recoveryView`, and `muscleView` in `tool/js/bridge-inventory.mjs`. Generated 32 new fixture cases in `tool/js/fixture-cases/phase4.mjs` with deterministic TZ checks passing across UTC, Asia/Kolkata, and America/Los_Angeles. Regenerated `tool/parity/parity_fixtures_data.dart`.

---

## Changes Implemented

### 1. Vendored Sources & Bundle
- `third_party/opengym/lib/recovery-view.js`:
  - Vendored from openGym v1.3.8.
  - Exposes `fatigueStateOf(value)`.
- `third_party/opengym/lib/strength-exercises.js`:
  - Vendored from openGym v1.3.8.
  - Exposes `strengthExerciseRowsForMuscle(S, now, slug)` and helpers.
- `third_party/opengym/lib/MANIFEST.sha256`:
  - Added checksums for both files; integrity confirmed via `shasum -a 256 -c`.
- `tool/gen_js_bundle.sh`:
  - Added new vendored files and `tool/js/shims/muscle-view-shim.js` to `FILES` and metafile `allowed` inputs list.
- `tool/js/entry.js`:
  - Exported `recoveryView` and `muscleView` namespaces.
- `assets/js/opengym-lib.bundle.js`:
  - Rebuilt bundle (1,104,896 bytes, SHA-256: `bb1e086c1cb75574e7f61cb2f4f1169cba7a2b01e4cd8eeb047fc1151795d556`).

### 2. Muscle View Shim
- `tool/js/shims/muscle-view-shim.js`:
  - Copied verbatim openGym view logic for `muscleBalance`, `fatigueView`, `strengthView`, and `muscleIndex`.
  - Kept all load, level bucketing, rounding, ranking, and threshold constants in JS.
  - Hard-set filtering predicate (`on ? isHardSet : null`) executed internally in JS.

### 3. Inventory & Parity Fixtures
- `tool/js/bridge-inventory.mjs`:
  - Extended `muscles` functions with `musclesOf`, `loadOf`, `loadOfWorkouts`, `loadOfActive`, `loadOfRoutine`, `levelsOf`, `rankOf`, `muscleBalanceWindow`, and constants with `INERT`.
  - Added `recoveryView` namespace (`fatigueStateOf`).
  - Added `muscleView` namespace (`muscleBalance`, `fatigueView`, `strengthView`, `muscleIndex`, `FATIGUE_LEVELS`, `STRENGTH_LEVELS`).
- `tool/js/gen-fixtures.mjs`:
  - Imported `recoveryView` and `muscleView`, registered `phase4` fixture cases.
- `tool/js/fixture-cases/phase4.mjs`:
  - Defined 32 test cases covering all 13 newly bridged functions with explicit timestamps and dates.
- `tool/fixtures/js-parity/phase4.json`:
  - Generated parity fixture outputs for Phase 4 functions.
- `tool/parity/parity_fixtures_data.dart`:
  - Generated Dart fixture data with 295 total cases.

---

## Verification Results
- `bash tool/gen_js_bundle.sh`: Metafile input audit PASSED (32 inputs).
- `bash tool/gen_js_fixtures.sh`:
  - TZ=Asia/Kolkata match confirmed.
  - TZ=America/Los_Angeles match confirmed.
- Inventory checks:
  - 13 new bridged functions verified in `parity_fixtures_data.dart`.
  - 13 unique functions verified in `phase4.json`.
  - 32 cases in `phase4.mjs`.
- Zero test files added; all rules and licenses satisfied.
