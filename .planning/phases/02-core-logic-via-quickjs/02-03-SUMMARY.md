# Phase 2 Plan 03 Summary: JsEngineService Core & Multi-Engine Smoke Verification

## Outcome
Implemented the JS-02 engine service (`JsEngineService`), strict coercion codec (`js_codec.dart`), bridge exception hierarchy (`js_bridge_exception.dart`), registered the bundled asset in `pubspec.yaml`, wired the service into application bootstrap and dependency injection with fallback recovery, and verified all 8 smoke assertions on both target engines: QuickJS on Android and JavaScriptCore on iOS Simulator.

## Smoke Test Results

### Android (QuickJS)
- **Result:** `ENGINE_SMOKE RESULT: PASS 8/8 engine=QuickJS`
- **Diagnostics:** `{"replaceAll":true,"normalize":true,"intl":false,"optionalChainingNative":true,"engine":"no-navigator"}`
- **Load Time (`LOAD_MS`):** `1049` ms
- **Device:** `sdk gphone16k arm64` (emulator-5554, Android 17 API 37)

### iOS Simulator (JavaScriptCore)
- **Result:** `ENGINE_SMOKE RESULT: PASS 8/8 engine=JavaScriptCore`
- **Diagnostics:** `{"replaceAll":true,"normalize":true,"intl":true,"optionalChainingNative":true,"engine":"no-navigator"}`
- **Load Time (`LOAD_MS`):** `106` ms
- **Device:** `iPhone 17 Pro` (iOS 26.5 Simulator)

### Assertions Verified on Both Engines
1. `check1_namespaces_meta`: All 8 namespaces loaded and `meta.openGymVersion == '1.3.8'`
2. `check2_estimate1rm`: `onerm.estimate1RM(100, 5) == 116.7`
3. `check3_undefined_and_brzycki`: `jsUndefined` sentinel applies default formula (`116.7`), explicit `'brzycki'` yields `112.5` (matches Node)
4. `check4_plate_split`: `bar.plateSplit(100, 20) == 40`
5. `check5_history_set_label`: `history.setLabel` returns `"100×5"` without error, proving `i18n-core` and string handling work
6. `check6_injection_probe`: Payload containing quotes, semicolons, try/catch, and `\u2028` parses safely as data, returning `"work"`
7. `check7_non_existent_function`: Calling non-existent function throws `JsBridgeExceptionKind.call`
8. `check8_bad_path`: Invalid path format throws `ArgumentError`

## Deviations & Pipeline Notes
- No bundle pipeline deviations required; the esbuild ES2019 IIFE with replaceAll banner polyfill succeeded on both QuickJS and JavaScriptCore without modifications.
- CocoaPods (`1.17.0`) generated `ios/Podfile`, `ios/Podfile.lock`, and configured workspace xcconfig integration cleanly on first simulator run.

## Artifacts Created & Modified
- `pubspec.yaml`: Registered `assets/js/opengym-lib.bundle.js` under `flutter.assets`
- `lib/core/js/js_bridge_exception.dart`: `JsBridgeException` with path, message, stack, and kind
- `lib/core/js/js_codec.dart`: `jsUndefined` sentinel, `JsonEncodable` interface, strict type coercion helpers
- `lib/core/js/js_engine_service.dart`: Single evaluation service with safe injection-free call protocol
- `lib/app/dependencies.dart`: Added `jsEngine` to `AppDependencies`
- `lib/app/app.dart`: Provided `jsEngine` via `MultiRepositoryProvider`
- `lib/main.dart`: Initialized `JsEngineService.load()` during bootstrap with database teardown and error screen fallback
- `tool/parity/parity_types.dart`: Shared parity dispatch contract and JSON converters
- `tool/parity/engine_smoke_main.dart`: Cross-platform smoke entrypoint
- `ios/Podfile`, `ios/Podfile.lock`, `ios/Flutter/*.xcconfig`, `ios/Runner.xcodeproj/*`: iOS CocoaPods configuration
