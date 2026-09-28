# Phase 2 Plan 08: JS Parity Verification Harness Summary

Exact IEEE-754 mathematical parity has been achieved and verified across both target JS runtime engines (QuickJS on Android, JavaScriptCore on iOS) for all 167 vitest-derived fixture cases.

## Execution Details

- **Plan:** `02-08-PLAN.md`
- **Wave:** 4 (Final)
- **Status:** Complete
- **Requirements Satisfied:** JS-03, JS-04
- **Date:** 2026-09-28

---

## Parity Results

### iOS Simulator (`JavaScriptCore`)
```
==> Running openGym JS parity harness on device: 6FF0B979-9BC3-4DAF-8274-C3F24BD0F7AD
flutter: PARITY bar 22/22
flutter: PARITY history 32/32
flutter: PARITY onerm 20/20
flutter: PARITY progression 35/35
flutter: PARITY recovery 14/14
flutter: PARITY session 10/10
flutter: PARITY workout-model 34/34
flutter: PARITY COVERAGE 63/114 inventory functions exercised
flutter: PARITY RESULT: PASS 167/167 engine=JavaScriptCore openGym=1.3.8 source=2190ad561541
```

### Android Emulator (`QuickJS`)
```
==> Running openGym JS parity harness on device: emulator-5554
I/flutter: PARITY bar 22/22
I/flutter: PARITY history 32/32
I/flutter: PARITY onerm 20/20
I/flutter: PARITY progression 35/35
I/flutter: PARITY recovery 14/14
I/flutter: PARITY session 10/10
I/flutter: PARITY workout-model 34/34
I/flutter: PARITY COVERAGE 63/114 inventory functions exercised
I/flutter: PARITY RESULT: PASS 167/167 engine=QuickJS openGym=1.3.8 source=2190ad561541
```

---

## Key Artifacts Delivered

1. **`lib/core/js/opengym_js.dart`**: Unified barrel export providing access to `JsEngineService`, `JsCodec`, `JsBridgeException`, all module facades, and all domain models.
2. **`tool/parity/parity_compare.dart`**: Exact JSON deep equality comparator with zero epsilon / tolerance. Includes 64-bit IEEE-754 bit-level ULP distance diagnostics for float debugging.
3. **`tool/parity/parity_main.dart`**: Standalone device-run Flutter entrypoint executing all 167 fixture cases against active engines. Refuses stale bundles (`sourceSha256` check) and enforces 100% dispatch inventory coverage against `kBridgeInventory`.
4. **`tool/run_parity.sh`**: One-command runner script capturing logs in `build/parity-logs/` and parsing `PARITY RESULT:` exit status.
5. **`tool/parity/README.md`**: Architecture documentation explaining headless constraints, no-test compliance, exact comparison philosophy, and artifact regeneration commands.

---

## Deviations & Fixes During Verification

1. **`progression.stallCount` optional `policy`**:
   - Upstream JS `stallCount(sessions, policy)` accepts an omitted/undefined `policy` parameter for linear/greyskull routines.
   - Updated `ProgressionJs.stallCount` to make `policy` optional (`[String? policy]`), passing `jsUndefined` when null.
   - Updated `progression_dispatch.dart` to check `hasArg(args, 1)` rather than unconditionally casting `args[1]` as `String`.

2. **`progression.addStep` optional `inc`**:
   - Fixed argument cast in `progression_dispatch.dart` to use `hasArg(args, 2)` before casting, avoiding `_JsUndefined` type cast exceptions.

3. **`workoutModel.dropsOf`, `clustersOf`, `extraVolumeOf` defensive handling**:
   - Upstream JS defensive tests pass `null` or empty objects to test resilience against missing arrays (`wm-020`).
   - Updated `WorkoutModelJs.dropsOf`, `clustersOf`, and `extraVolumeOf` to accept nullable `SetEntry?`, passing `null` or `jsUndefined` safely to the engine.
   - Updated `workout_model_dispatch.dart` to guard `args[0]` with `is Map` check before attempting `SetEntry.fromJson`.

4. **`tool/run_parity.sh` log parsing regex**:
   - Flutter device logs prefix stdout with `flutter: ` (iOS) or `I/flutter: ` (Android).
   - Updated regex in `tool/run_parity.sh` to match `(flutter: )?PARITY RESULT:` and `PARITY FAIL` consistently.

---

## Verification Gates Passed

- [x] `bash tool/run_parity.sh 6FF0B979-9BC3-4DAF-8274-C3F24BD0F7AD` (iOS JavaScriptCore: 167/167 PASS)
- [x] `bash tool/run_parity.sh emulator-5554` (Android QuickJS: 167/167 PASS)
- [x] `bash tool/js04_audit.sh` (JS-04 mathematical delegation audit: PASS)
- [x] `flutter analyze` (0 errors, 0 warnings: "No issues found!")
- [x] `bash tool/gen_js_bundle.sh && git diff --exit-code assets/js/opengym-lib.bundle.js` (Deterministic bundle)
- [x] `bash tool/gen_js_fixtures.sh && git diff --exit-code tool/fixtures/js-parity tool/parity/parity_fixtures_data.dart` (Deterministic fixtures)
