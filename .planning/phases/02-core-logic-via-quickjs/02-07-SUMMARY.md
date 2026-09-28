# Phase 2 Plan 07: History & Session Facades and Dispatch Tables Summary

**Execution Date:** 2026-09-28
**Plan:** `.planning/phases/02-core-logic-via-quickjs/02-07-PLAN.md`
**Status:** Completed

---

## 1. Overview & Core Value

Plan 02-07 exposes typed Dart calls for openGym's `history.js`, `session-start.js`, and `session-merge.js` modules, providing high-level access to exercise configuration, effort rating scales, superset grouping, routine scheduling, set building (with warm-up ramps and intensifier plans), weight cascading, and combined session merging running in the bundled JavaScript engine via `JsEngineService`.

All planned sets, cascades, warm-up ramps, and multi-routine merges delegate 100% to openGym's original JavaScript implementation without re-derivation in Dart (JS-04). User-facing presentation strings (`setLabel`, `exLine`, and `fmtSec`) are intentionally omitted from the bridge because they depend on `i18n.js` / `i18n-core.js` and would produce only English output; Phase 3 and Phase 8 own all UI presentation strings in Dart.

---

## 2. Key Deliverables & Artifacts

### A. History Module
- **`lib/core/js/models/history_models.dart`**:
  - `EffortScale`: Rating scale parameters for RIR and RPE (`f`, `hd`, `step`, `min`, `max`).
  - `BuildSetsOptions`: Options for set generation (`step`, `preferLast`, `useTarget`).
  - `PinnedNote`: Pinned session note (`note`, `d`).
  - `TrainingDay`: Next trainable day resolution (`iso`, `weekday`, `routines`, `routine`).
  - `CombinedSession`: Multi-routine session structure (`entries`, `routineIds`, `routines`).
  - All models extend `Equatable`, implement `JsonEncodable`, and use `JsonReader` with `extra` passthrough.
- **`lib/core/js/modules/history_js.dart`**:
  - `HistoryJs` facade and `extension HistoryJsAccess on JsEngineService`.
  - Methods covering all 45 inventory functions:
    - Exercise configuration & effort: `modeOf`, `isTimed`, `isBw`, `isPerSide`, `sideReps`, `repStep`, `stepEffort`, `capEffort`, `effortOf`, `defaultConfig`, `freestyleConfig`.
    - Superset & routine editing: `cleanupSg`, `pairAdjacent`, `unpairSuperset`, `supersetUnits`, `moveSupersetUnit`, `unitOf`.
    - Entries & routine lookup: `entryExcluded`, `lastEntryFor`, `pinnedNoteFor`, `exNoteFor`, `bestWeightFor`, `effectiveRoutineIds`, `effectiveRoutines`, `effectiveRoutineId`, `effectiveRoutine`, `nextTrainingDay`.
    - Set generation & intensifiers: `buildSets`, `applyIntensifierPlan`, `cascadeWeight`, `rerampWarmups`, `insertWarmupRow`, `removeRowAt`.
    - Workout progress & volume: `workoutVolume`, `setUnits`, `doneUnits`, `setUnitsTotal`, `setsDone`, `setsDoneActive`, `workSetsDone`, `lastBW`, `streakWeeks`.
    - Metrics: `metricRowsForEntry`, `metricModeForEntry`, `bestWeightForEntry`.
  - Constants: `effort` (EFFORT), `noteMax` (NOTE_MAX), `maxPlannedWarmups` (MAX_PLANNED_WARMUPS).
- **`tool/parity/dispatch/history_dispatch.dart`**:
  - `historyDispatch(engine)` dispatch table mapping all 45 test fixture function names to typed facade calls.

### B. Session Start & Merge Modules
- **`lib/core/js/modules/session_js.dart`**:
  - `SessionStartJs` facade and `extension SessionStartJsAccess on JsEngineService`:
    - `buildSessionEntries(st, r)`: Builds session entries from a single routine, applying progression, step increments, warm-ups, and intensifiers.
  - `SessionMergeJs` facade and `extension SessionMergeJsAccess on JsEngineService`:
    - `buildCombinedEntries(st, routineIds)`: Merges entries from multiple routines in order, stamping `entry.rid`.
    - `deriveSessionName(names)`: Computes the merged session title (e.g. "Rehab + Core" or "Rehab + Core + 2 more").
- **`tool/parity/dispatch/session_dispatch.dart`**:
  - `sessionStartDispatch(engine)` and `sessionMergeDispatch(engine)` dispatch tables mapping fixture cases to facade calls.

---

## 3. Verification & Parity Checks

1. **Static Analysis:**
   - `flutter analyze` passed with 0 issues.
2. **Bridge Inventory Coverage:**
   - 100% coverage verified for all functions in `history`, `sessionStart`, and `sessionMerge`.
   - All literal function path strings present in facades and dispatch tables.
3. **JS-04 Audit:**
   - `bash tool/js04_audit.sh` passed.
   - Grep verification confirmed zero occurrences of `reduce(`, `fold(`, `* s.`, `.w *`, `round(`.

---

## 4. Deviations from Plan

- None. All method signatures and types match the plan specification and openGym JavaScript implementation.
