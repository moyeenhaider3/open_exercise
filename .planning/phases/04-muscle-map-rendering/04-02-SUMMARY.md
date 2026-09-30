# Plan 04-02 Summary: Typed Muscle Facades, Codec Extensions & Device Parity Verification

## Executive Summary
Plan `04-02` implemented the Dart side of the Phase 4 bridge extension, providing strictly typed models, facades, and complete device parity verification on a physical/emulated Android device:
- **Codec Extensions**: Added `jsIntMap` and `jsStringMap` to `lib/core/js/js_codec.dart` with strict type checking and `JsBridgeException.type` validation.
- **Typed Muscle Models**: Created `lib/core/js/models/muscle_models.dart` defining 8 immutable `final class` models extending `Equatable`:
  - `ThresholdRule` (`at`, `level`, `exclusive`).
  - `MuscleRank` (`worked`, `missed`).
  - `MuscleTopRow` (`slug`, `pct`).
  - `MuscleBalanceView` (`inWinCount`, `rated`, `on`, `load`, `levels`, `worked`, `missed`, `top`, `sets`).
  - `FatigueView` (`fatigue`, `levels`, `states`).
  - `DetrainedRow` (`slug`, `pct`, `sets90`, `weeks`).
  - `StrengthExerciseRow` (`id`, `name`, `weight`, `primary`, `est`, `estDate`, `decay`, `decayPct`, `current`).
  - `StrengthView` (`strength`, `levels`, `strengthFloor`, `detrained`, `exercises`).
- **MusclesJs & RecoveryJs**:
  - Added `inert`, `musclesOf`, `loadOf`, `loadOfWorkouts`, `loadOfActive`, `loadOfRoutine`, `levelsOf`, `rankOf`, and `muscleBalanceWindow` to `MusclesJs`.
  - Added `fatigueStateOf(num? value)` to `RecoveryJs`.
- **MuscleViewJs Facade**:
  - Implemented `muscleBalance`, `fatigueView`, `strengthView`, `muscleIndex`, `fatigueLevels`, and `strengthLevels` with zero Dart-side aggregation or math.
  - Added `engine.muscleView` extension accessor.
- **Engine Namespace Configuration**: Added `recoveryView` and `muscleView` to allowed namespaces in `JsEngineService`.
- **Runtime Portability**: Polyfilled `Array.prototype.at` in `tool/gen_js_bundle.sh` and modernized array indexing in `muscle-view-shim.js` for ES2019 / QuickJS compatibility on Android.
- **Device Parity Verification**: Created `tool/parity/dispatch/phase4_dispatch.dart` covering all 13 inventory functions. Ran `tool/run_parity.sh emulator-5554` resulting in `PARITY RESULT: PASS 295/295` on `QuickJS`.

---

## Changes Implemented

### 1. Codec & Engine
- `lib/core/js/js_codec.dart`:
  - Added `jsIntMap(Object? v, String path)` and `jsStringMap(Object? v, String path)`.
- `lib/core/js/js_engine_service.dart`:
  - Added `'recoveryView'` and `'muscleView'` to `namespaces` set.
- `tool/gen_js_bundle.sh`:
  - Added `Array.prototype.at` polyfill to IIFE banner.
- `tool/js/shims/muscle-view-shim.js`:
  - Adjusted `bodyweightKgOf` to use standard length indexing instead of `.at(-1)`.

### 2. Models & Facades
- `lib/core/js/models/muscle_models.dart`:
  - 8 new typed models with strict `fromJson`/`toJson` and `Equatable` props.
- `lib/core/js/modules/muscles_js.dart`:
  - Extended with all 8 new muscle calculation functions and `inert` getter.
- `lib/core/js/modules/recovery_js.dart`:
  - Added `fatigueStateOf` calling `recoveryView.fatigueStateOf`.
- `lib/core/js/modules/muscle_view_js.dart`:
  - New facade calling `muscleView.*` functions and reading level thresholds.
- `lib/core/js/opengym_js.dart`:
  - Exported `models/muscle_models.dart` and `modules/muscle_view_js.dart`.

### 3. Parity Dispatch & Verification
- `tool/parity/dispatch/phase4_dispatch.dart`:
  - Implemented dispatch for all 13 new bridged functions.
- `tool/parity/parity_main.dart`:
  - Integrated `phase4Dispatch(engine)`.

---

## Verification Results
- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS (0 forbidden imports or math patterns).
- `bash tool/run_parity.sh emulator-5554`:
  - 295/295 cases passed (100% exact parity with openGym / vitest).
  - 0 missing dispatch, 0 extra dispatch.
  - Phase 4: 32/32 cases passed.
