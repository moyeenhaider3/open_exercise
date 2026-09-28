# Phase 2 Plan 05: onerm, bar, workoutModel Facades & JS-04 Enforcement Summary

**Execution Date:** 2026-09-28
**Plan:** `.planning/phases/02-core-logic-via-quickjs/02-05-PLAN.md`
**Status:** Completed

---

## 1. Overview & Core Value

Plan 02-05 implements typed Dart facades for openGym's `onerm.js`, `bar.js`, and `workout-model.js` modules, providing high-level, type-safe access to domain logic running inside the bundled JavaScript runtime via `JsEngineService`.

In addition, it resolves Phase 1 code review finding **CR-02** by eliminating the hand-ported `_normalizedPhase`, `resolvedPhaseOr`, `resolvedPhase`, and `resolvedType` methods from `SetEntry`. Finally, it introduces `tool/js04_audit.sh` to mechanically enforce rule **JS-04** (zero hand-ported mathematical formulas in Dart).

---

## 2. Key Deliverables & Artifacts

### A. Onerm Module
- **`lib/core/js/models/onerm_models.dart`**:
  - `OnermBestSet`: Best 1RM estimate from an entry's completed sets (`est`, `w`, `r`).
  - `E1rmPoint`: Chronological trend point (`t`, `d`, `y`, `w`, `r`).
  - `OnermBest`: All-time personal best estimate (`est`, `w`, `r`, `d`, `t`).
  - `OnermRecord`: Personal record notification data (`est`, `w`, `r`, `prev`).
  - All models extend `Equatable`, implement `JsonEncodable`, and use `JsonReader` with `extra` passthrough.
- **`lib/core/js/modules/onerm_js.dart`**:
  - `OnermJs` facade and `extension OnermJsAccess on JsEngineService`.
  - Methods: `estimate1RM`, `bestSetOf`, `e1rmSeries`, `best1RM`, `is1RMRecord`.
  - Getters: `repCap` (12), `defaultFormula` ('epley'), `formulas` (keys of FORMULAS).
  - All math, rep cap exclusions, and warmup exclusions are evaluated in JavaScript.
- **`tool/parity/dispatch/onerm_dispatch.dart`**:
  - `onermDispatch(engine)` dispatch table mapping test fixture function names to typed facade calls.

### B. Bar Module
- **`lib/core/js/modules/bar_js.dart`**:
  - `BarJs` facade and `extension BarJsAccess on JsEngineService`.
  - Methods: `usesBar`, `defaultBarWeight`, `isNoBar`, `hasBarOverride`, `barWeightFor`, `plateSplit`.
  - Getters: `defaultBarKg`, `defaultBarLb`.
  - `exOrId` argument validator ensuring inputs are strictly `String`, `Map<String, Object?>`, or `null` (T-02-18 mitigation).
- **`tool/parity/dispatch/bar_dispatch.dart`**:
  - `barDispatch(engine)` dispatch table mapping bar fixture cases to facade calls.

### C. WorkoutModel Module
- **`lib/core/js/modules/workout_model_js.dart`**:
  - `WorkoutModelJs` facade and `extension WorkoutModelJsAccess on JsEngineService`.
  - Covers all 33 `workoutModel` inventory functions:
    - Phase resolution: `phaseForSet`, `isWarmupRow`.
    - Set typing & intensifiers: `setType`, `isDropSet`, `isRestPauseSet`, `dropsOf`, `clustersOf`, `extraVolumeOf`.
    - Set manipulation: `addDrop`, `addCluster`, `removeDropAt`, `removeClusterAt`, `setDropAt`, `setClusterAt`.
    - Drop & cluster stepping: `nextDropWeight`, `nextBurstReps`, `splitBurstReps`.
    - Unilateral (per-side) logic: `isSideSet`, `hasCompletedWork`, `completedVolumeOf`, `makeSideSet`, `syncSideAggregate`, `setSideField`, `toggleSide`, `addSideDrop`, `removeSideDropAt`, `setSideDropAt`, `addSideCluster`, `removeSideClusterAt`, `setSideClusterAt`.
    - Mode resolution: `normalizeMode`, `modeForSet`, `modeForEntry`.
  - Contains no string parsing or re-implemented logic.
- **`tool/parity/dispatch/workout_model_dispatch.dart`**:
  - `workoutModelDispatch(engine)` dispatch table mapping workoutModel fixture cases to facade calls.

### D. SetEntry Cleanup (CR-02 / JS-04)
- **`lib/core/models/set_entry.dart`**:
  - Removed `_normalizedPhase`, `resolvedPhaseOr`, `resolvedPhase`, and `resolvedType`.
  - `SetEntry` is now a pure data transfer and persistence model. Phase and type resolution must be invoked via `engine.workoutModel.phaseForSet` / `setType`.

### E. JS-04 Mechanical Audit
- **`tool/js04_audit.sh`**:
  - Validates:
    - (a) Zero occurrences of removed Phase 1 stopgap identifiers (`_normalizedPhase`, etc.).
    - (b) Zero `dart:math` imports in `models`, `js`, or feature `bloc` layers.
    - (c) Zero formula/constant fingerprints (`/ 30`, `36 / (37`, `pow(`, `129600000`, etc.).
    - (d) Zero domain algorithm declarations outside `lib/core/js/modules/`.
  - Verified with both positive execution (PASS) and negative probe injection (FAILED with exit 1).

---

## 3. Verification & Parity Checks

1. **Static Analysis:**
   - `flutter analyze` passed with 0 issues.
2. **Bridge Inventory Coverage:**
   - 100% coverage verified for all functions in `onerm`, `bar`, and `workoutModel`.
   - All literal function path strings present in facades and dispatch tables.
3. **JS-04 Audit:**
   - `bash tool/js04_audit.sh` prints `JS-04 audit: PASS` and exits 0.

---

## 4. Deviations & Discoveries

- In `bar_js.dart`, `exOrId` is permitted to be `null` in addition to `String` and `Map<String, Object?>` to support openGym test cases such as `usesBar(null) => false`.
- No signature deviations from `02-05-PLAN.md`.
