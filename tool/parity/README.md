# openGym JS Parity Verification Harness

This directory contains the verification harness that proves 1:1 mathematical parity between `open_exercise`'s typed Dart facades and openGym's original JavaScript domain logic.

## Architecture & Design Rationale

### Why a Device-Run Flutter App (Not `dart run`)?
As documented in `.planning/phases/02-core-logic-via-quickjs/02-FLUTTER-JS-SPIKE.md`, `flutter_js` relies on native platform bindings (`QuickJS` on Android, `JavaScriptCore` on iOS) and transitively depends on `package:flutter` and `dart:ui`. Consequently, running headless CLI scripts via `dart run` fails at runtime with missing symbol errors.

The parity harness is designed as a standalone Flutter application entrypoint (`tool/parity/parity_main.dart`) that boots the Flutter engine on an active emulator or simulator, executes the full parity suite, logs results to stdout/file, displays the outcome, and exits with status 0 (PASS) or 1 (FAIL).

### Strict No-Tests Rule
Per project guidelines in `CLAUDE.md`, this repository strictly forbids test files (`test/`, `integration_test/`, `*_test.dart`, and Flutter test SDK imports). Parity verification is treated as an autonomous verification harness and validation tool under `tool/`, not a standard unit test suite.

### Exact Parity (Zero Epsilon / Tolerance)
Per requirement **JS-03**, parity comparisons use exact `==` IEEE-754 double comparison (`tool/parity/parity_compare.dart`). No epsilon, delta, or tolerance is permitted. If two doubles diverge, the comparator logs the Units in the Last Place (ULP) distance for root cause analysis.

### Strict JS-04 Compliance
Per requirement **JS-04**, domain math (1RM, progression steps, deloads, plate math, recovery decay) must not be hand-coded in Dart; all calculations delegate to the bundled openGym JavaScript runtime via `JsEngineService`. This invariant is mechanically enforced by `tool/js04_audit.sh`.

---

## Directory Structure

```
tool/parity/
├── README.md                   # This document
├── engine_smoke_main.dart      # Quick 8-point engine diagnostic app
├── parity_compare.dart         # Exact JSON deep comparator with ULP diagnostics
├── parity_fixtures_data.dart   # Auto-generated base64-encoded vitest fixtures & inventory
├── parity_main.dart            # Flutter app entrypoint running all 167 fixture cases
├── parity_types.dart           # Shared types, argument helpers, and JSON encoders
└── dispatch/                   # Dispatch tables mapping JS paths to Dart facade calls
    ├── bar_dispatch.dart
    ├── history_dispatch.dart
    ├── onerm_dispatch.dart
    ├── progression_dispatch.dart
    ├── recovery_dispatch.dart
    ├── session_dispatch.dart
    └── workout_model_dispatch.dart
```

---

## Running the Parity Suite

### Prerequisites
An Android emulator or iOS simulator must be running:
```bash
# Check available devices
flutter devices
```

### Running via CLI Runner Script
Use `tool/run_parity.sh` with the target device ID:

```bash
# Android Emulator (QuickJS)
bash tool/run_parity.sh emulator-5554

# iOS Simulator (JavaScriptCore)
bash tool/run_parity.sh 6FF0B979-9BC3-4DAF-8274-C3F24BD0F7AD
```

Logs are captured in `build/parity-logs/parity-<device-id>.log`.

---

## Artifact Generation & Regeneration

> **WARNING:** Never edit fixture files under `tool/fixtures/js-parity/` or `tool/parity/parity_fixtures_data.dart` by hand!

### 1. Bundle Regeneration
When updating vendored openGym JavaScript files in `third_party/opengym/lib/`:
```bash
bash tool/gen_js_bundle.sh
git diff --exit-code assets/js/opengym-lib.bundle.js
```

### 2. Fixture Regeneration
To re-run vitest against openGym upstream tests and re-generate parity fixtures:
```bash
bash tool/gen_js_fixtures.sh
git diff --exit-code tool/fixtures/js-parity tool/parity/parity_fixtures_data.dart
```

### 3. JS-04 Math Audit Gate
To verify that no domain math formulas or disallowed imports have leaked into Dart:
```bash
bash tool/js04_audit.sh
```
