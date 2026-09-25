# Phase 2 Plan 02 Summary: flutter_js Spike & Platform De-Risking

## Outcome
Added `flutter_js: ^0.8.7`, audited the installed package source to capture the exact runtime API and engine-specific error semantics, resolved Kotlin JVM target compatibility for the Android QuickJS build, executed a headless probe proving `flutter run -t` is required for the parity harness, probed the iOS build path, and completed the CocoaPods installation decision with `pod 1.17.0` installed.

## Key Findings
- **Real flutter_js API:**
  - `getJavascriptRuntime({bool forceJavascriptCoreOnAndroid = false, bool xhr = true, Map<String, dynamic>? extraArgs = const {}})`
  - Crucial flag: `xhr` defaults to `true` (enables HTTP fetch shim). Must pass `xhr: false` for strict offline sandboxing.
  - `JsEvalResult` fields: `stringResult`, `rawResult`, `isPromise`, `isError`. **No `stacktrace` property exists**.
- **Engine Error Handling:**
  - QuickJS: throws JSError exceptions setting `isError: true`.
  - JavaScriptCore: computes `isError: result.startsWith('ERROR:')`. String-prefix heuristic means valid strings starting with `"ERROR:"` can be misidentified.
  - Bridge requirement: All calls must be wrapped in a JS try/catch envelope returning JSON `{ ok: true, data: ... }` / `{ ok: false, error: ... }`.
- **Headless Verdict:**
  `HEADLESS: NO — parity harness must be a flutter run -t app entrypoint`
  (Standalone `dart run` fails because `flutter_js` imports Flutter framework services that depend on `dart:ui`).
- **Android Build Probe (QuickJS):**
  - Resolved Gradle JVM target validation (`compileDebugJavaWithJavac` 11 vs `compileDebugKotlin` 1.8) via `kotlin.jvm.target.validation.mode=warning` in `android/gradle.properties`.
  - `flutter build apk --debug` succeeded in 11.4s, generating `build/app/outputs/flutter-apk/app-debug.apk`.
- **iOS Toolchain Decision:**
  - `CocoaPods decision: claude-installs (timestamp: 2026-09-25T17:39:00+05:30, pod version: 1.17.0)`
  - Installed `cocoapods 1.17.0` via Homebrew (`/opt/homebrew/bin/pod`). Ready for Plan 02-03's iOS smoke build.

## Artifacts Created & Modified
- `pubspec.yaml`, `pubspec.lock`: Added `flutter_js: ^0.8.7`
- `android/gradle.properties`: Added `kotlin.jvm.target.validation.mode=warning`
- `.planning/phases/02-core-logic-via-quickjs/02-FLUTTER-JS-SPIKE.md`: Comprehensive API reference, engine difference notes, headless verdict, build matrix, and device inventory
- `.planning/phases/02-core-logic-via-quickjs/02-02-SUMMARY.md`: This summary
