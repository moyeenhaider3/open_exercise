# Phase 2 Plan 06: Progression & Recovery Facades and Dispatch Tables Summary

**Execution Date:** 2026-09-28
**Plan:** `.planning/phases/02-core-logic-via-quickjs/02-06-PLAN.md`
**Status:** Completed

---

## 1. Overview & Core Value

Plan 02-06 exposes typed Dart calls for openGym's `progression.js` and `recovery.js` modules, providing complete access to automatic progression suggestions (Linear, Greyskull LP, Double Progression, Time, and Deload logic) and muscle recovery / fatigue decay models running in the bundled JavaScript engine via `JsEngineService`.

All algorithms, saturation curves, exponential decays, and Epley candidate optimizations run 100% in JavaScript without re-derivation in Dart (JS-04). Wall-clock timestamps are never queried inside the recovery module, guaranteeing deterministic evaluations via caller-injected timestamps (`nowMs`).

---

## 2. Key Deliverables & Artifacts

### A. Progression Module
- **`lib/core/js/models/progression_models.dart`**:
  - `Prescription`: The next target recommendation (`policy`, `kind`, `weight`, `reps`, `sec`, `sets`, `target1RM`, `deloadFactor`, `why` template arguments).
  - `DeloadCandidateQuery`: Input query for Epley candidate search (`currentWeight`, `targetWeight`, `targetReps`, `step`, `factor`, `reps`, `repsMin`, `perSide`).
  - `DeloadCandidate`: Candidate results (`weight`, `reps`, `epley`, `error`, `repChange`, `fallback`, `target1RM`, `factor`, `upper`, `bottom`).
  - `SessionSummary`: Reduced session scoring (`mode`, `target`, `goal`, `held`, `reps`, `weight`, `count`, `low`, `amrap`, `best`, `ok`, `d`).
  - All models extend `Equatable`, implement `JsonEncodable`, and use `JsonReader` with `extra` passthrough.
- **`lib/core/js/modules/progression_js.dart`**:
  - `ProgressionJs` facade and `extension ProgressionJsAccess on JsEngineService`.
  - Methods covering all 17 inventory functions:
    - Factors & increments: `isValidDeloadFactor`, `deloadFactorOf`, `epley1RM`, `deloadTarget1RM`, `defaultIncrement`, `weightIncrement`.
    - Policy & stepping: `policyFor`, `snapWeight`, `addStep`, `stepWeight`, `deloadTo`.
    - Session evaluation & deloads: `selectDeloadCandidate`, `readSession`, `sessionsFor`, `stallCount`.
    - Prescription application: `nextPrescription`, `applyPrescription`.
  - Constants: `policies`, `policiesFor`, `deloadFactor`, `deloadAfter`, `deloadFactorMin`, `deloadFactorMax`, `defaultSecIncrement`, `maxBwSets`.
- **`tool/parity/dispatch/progression_dispatch.dart`**:
  - `progressionDispatch(engine)` dispatch table mapping test fixture function names to typed facade calls.

### B. Recovery Module
- **`lib/core/js/models/recovery_models.dart`**:
  - `RecoveryOptions`: Configuration options (`unit`, `extra`).
- **`lib/core/js/modules/recovery_js.dart`**:
  - `RecoveryJs` facade and `extension RecoveryJsAccess on JsEngineService`.
  - Methods covering all 5 inventory functions:
    - Decay: `halfLifeDecay(ageMs, halfLifeMs)`.
    - Maps: `fatigueOf(workouts, nowMs, opts:)`, `strengthOf(workouts, nowMs, opts:)`.
    - Muscle lists: `fatiguedMuscles(workouts, nowMs, opts:)`, `detrainedMuscles(workouts, nowMs, opts:)`.
  - Constants: `fatigueRefVolume`, `fatigueMinSessions`, `fatigueHalfLifeMs`, `strengthFullMs`, `strengthHalfLifeMs`, `strengthFloor`, `fatigueStates`.
  - Constants are queried via `_engine.read` rather than hardcoded in Dart source.
- **`tool/parity/dispatch/recovery_dispatch.dart`**:
  - `recoveryDispatch(engine)` dispatch table mapping recovery fixture cases to facade calls.

---

## 3. Verification & Parity Checks

1. **Static Analysis:**
   - `flutter analyze` passed with 0 issues.
2. **Bridge Inventory Coverage:**
   - 100% coverage verified for all functions in `progression` and `recovery`.
   - All literal function path strings present in facades and dispatch tables.
3. **JS-04 Audit:**
   - `bash tool/js04_audit.sh` passed.
   - Grep verification confirmed zero occurrences of `DateTime.now`, `Math`, `pow`, `exp`, or math constant literals.

---

## 4. Deviations from Plan

- None. All method signatures and types match the plan specification and openGym JavaScript implementation.
