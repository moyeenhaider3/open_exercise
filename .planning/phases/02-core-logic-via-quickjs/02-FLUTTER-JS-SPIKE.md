# flutter_js 0.8.7 Spike & Compatibility Report

## Overview
De-risking spike for `flutter_js: ^0.8.7` conducted on 2026-09-25. This document records the empirical findings from the installed package source (`~/.pub-cache/hosted/pub.dev/flutter_js-0.8.7`), headless `dart run` probe, and platform build probes on Android and iOS.

---

## API (verified from installed source)

The actual API declared in `flutter_js` 0.8.7:

### Factory Function
```dart
JavascriptRuntime getJavascriptRuntime({
  bool forceJavascriptCoreOnAndroid = false,
  bool xhr = true,
  Map<String, dynamic>? extraArgs = const {},
});
```
- Android default runtime: `QuickJsRuntime2(stackSize: extraArgs?['stackSize'] ?? 1024 * 1024)`.
- iOS / macOS default runtime: `JavascriptCoreRuntime()`.
- Windows / Linux default runtime: `QuickJsRuntime2()`.
- Note: `xhr` defaults to `true`. When `true`, it calls `runtime.enableFetch()` which shims `fetch` using native HTTP. The bridge must pass `xhr: false` so bundled JS executes in a completely offline, sandbox environment with no network access.

### JsEvalResult
From `lib/js_eval_result.dart`:
```dart
class JsEvalResult {
  final String stringResult;
  final dynamic rawResult;
  final bool isPromise;
  final bool isError;

  JsEvalResult(this.stringResult, this.rawResult,
      {this.isError = false, this.isPromise = false});

  @override
  String toString() => stringResult;
}
```
**CRITICAL:** `JsEvalResult` has **no `stacktrace` field**. Any code referencing `result.stacktrace` fails to compile.

### JavascriptRuntime Methods
From `lib/javascript_runtime.dart`:
```dart
abstract class JavascriptRuntime {
  JsEvalResult evaluate(String code, {String? sourceUrl});
  Future<JsEvalResult> evaluateAsync(String code, {String? sourceUrl});
  void dispose();
  String jsonStringify(JsEvalResult jsValue);
  // ... channel and inspectable methods
}
```

---

## Error signalling per engine

### QuickJS (`QuickJsRuntime2`)
In `quickjs/quickjs_runtime2.dart`:
```dart
if (jsIsException(jsval) != 0) {
  jsFreeValue(ctx, jsval);
  JSError exception = _parseJSException(ctx);
  return JsEvalResult(exception.toString(), exception, isError: true);
}
```
Exceptions thrown in JS set `isError: true` and `stringResult` contains the exception message.

### JavaScriptCore (`JavascriptCoreRuntime`)
In `javascriptcore/jscore_runtime.dart`:
```dart
if (exceptionValue.isObject) {
  result =
      'ERROR: ${exceptionValue.toObject().getProperty("message").string} \n  at ${exceptionValue.toObject().getProperty("stack").string}';
} else {
  result = _getJsValue(jsValueRef);
  // ...
}
return JsEvalResult(
  result,
  exceptionValue.isObject ? exceptionValue.toObject().pointer : jsValueRef,
  isError: result.startsWith('ERROR:'),
  isPromise: isPromise,
);
```
**Vulnerability:** In JavaScriptCore, `isError` is computed purely via string prefix heuristic: `result.startsWith('ERROR:')`. If a valid JS call returns a string beginning with `"ERROR:"`, JavaScriptCore misclassifies it as an error (`isError == true`).

### Bridge Implication
The bridge **must never rely solely on `isError`**. Every Dart→JS invocation must be wrapped in an explicit JS try/catch envelope returning a standard JSON structure, e.g.:
```javascript
try {
  return JSON.stringify({ ok: true, data: OpenGymLib.onerm.estimate1RM(...) ?? null });
} catch (e) {
  return JSON.stringify({ ok: false, error: String(e && e.message ? e.message : e) });
}
```
The Dart bridge deserializes this JSON and checks `ok: true/false`.

---

## Value transport

On both engines:
- `stringResult` contains the string representation of the evaluated expression.
- When evaluating `JSON.stringify(...)`, `stringResult` contains the exact serialized JSON string.
- Dart safely parses this string with `jsonDecode(result.stringResult)`.
- Arguments passed from Dart must always be formatted with `jsonEncode` into the evaluation string to prevent code injection and format mismatches.

---

## Lifecycle

- **QuickJS:** `dispose()` closes the isolate port and frees the C context/runtime. `evaluateAsync()` is simply an asynchronous wrapper around synchronous C `jsEval()`. Default stack size is 1 MB (`1024 * 1024` bytes).
- **JavaScriptCore:** `dispose()` calls native `jSGlobalContextRelease(_globalContext)` and `jSContextGroupRelease(_contextGroup)`.
- Runtime instances should be created once at application startup and kept alive throughout the app lifecycle.

---

## Deviations from 02-RESEARCH.md

1. **No `stacktrace` property:** `02-RESEARCH.md` showed example code calling `loaded.stacktrace`. `JsEvalResult` only contains `stringResult`, `rawResult`, `isPromise`, `isError`.
2. **`xhr` defaults to `true`:** `02-RESEARCH.md` noted `xhr` should be disabled; the installed source confirms `xhr: true` calls `enableFetch()`. We must explicitly pass `xhr: false`.
3. **JSCore `isError` prefix heuristic:** Confirmed directly in `jscore_runtime.dart:104` (`result.startsWith('ERROR:')`).

---

## Headless verdict

HEADLESS: NO — parity harness must be a `flutter run -t` app entrypoint

**Evidence:**
A throwaway console Dart project configured with `flutter_js: 0.8.7` run via `dart run bin/main.dart` fails at compile time because `flutter_js` imports `package:flutter/services.dart` and `package:flutter/foundation.dart`, which depend on `dart:ui`. In a standalone Dart CLI environment, `dart:ui` does not exist:

```
../../../../../../Development/flutter/packages/flutter/lib/src/gestures/tap_and_drag.dart:1449:30: Error: 'Offset' isn't a type.
  Offset _getDeltaForDetails(Offset delta) => delta;
                             ^^^^^^
../../../../../../Development/flutter/packages/flutter/lib/src/gestures/velocity_tracker.dart:23:9: Error: 'Offset' isn't a type.
  final Offset pixelsPerSecond;
        ^^^^^^
Error: Compilation failed.
```

Therefore, all JS engine evaluations and the JS-03 parity harness must run inside a Flutter environment (`flutter run -t` targeting an emulator, simulator, or device).

---

## Build matrix

| Platform | Engine | Command | Result | Notes |
|---|---|---|---|---|
| Android | QuickJS | `flutter build apk --debug` | PASS (11.4s) | Kotlin Gradle target compatibility resolved with `kotlin.jvm.target.validation.mode=warning` in `android/gradle.properties`. Output: `build/app/outputs/flutter-apk/app-debug.apk`. |
| iOS Simulator | JavaScriptCore | `flutter build ios --simulator --debug` | FAIL (blocked on CocoaPods) | `Warning: CocoaPods not installed. Skipping pod install. CocoaPods not installed or not in valid state.` `flutter_js` provides only a `.podspec` (no SPM support). |

**Host Tooling Status:**
- `which pod`: /opt/homebrew/bin/pod
- `pod --version`: 1.17.0
- `brew --version`: Homebrew 7.0.1 (available at `/opt/homebrew/bin/brew`)

CocoaPods decision: claude-installs (timestamp: 2026-09-25T17:39:00+05:30, pod version: 1.17.0)

---

## Emulator/simulator inventory

### Connected Devices (`flutter devices`)
- `emulator-5554` • sdk gphone16k arm64 • Android 17 (API 37) (running Android emulator)
- `00008101-000A09C938E1401E` • Xcelore’s iPhone • iOS 26.5.2
- `macos` • Darwin-arm64
- `chrome` • Web

### Available Emulators (`flutter emulators`)
- `Medium_Phone` • Medium Phone • Generic • android
- `apple_ios_simulator` • iOS Simulator • Apple • ios

### Available iOS Simulators (`xcrun simctl list devices available`)
- iPhone 17 Pro (`6FF0B979-9BC3-4DAF-8274-C3F24BD0F7AD`)
- iPhone 17 Pro Max (`3C831D14-5253-4661-A2BA-DCE3092B38CB`)
- iPhone 17 (`B0093C1B-18C1-46C0-B56E-19DB0B58083A`)
- iPhone Air (`39C9B99A-6D3D-4C6E-92C7-D1721A55C5BF`)
- iPhone 17e (`85927C09-7F29-4764-94E4-7133B690F45C`)
- iPad Pro 13-inch (M5) (`E7DA6923-97EE-4174-B703-6B833A22F0E8`)
- iPad Air 13-inch (M4) (`445840EE-B4BB-47D3-B5B1-0D4108E5322B`)
