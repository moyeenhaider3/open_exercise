---
status: testing
phase: 02-core-logic-via-quickjs
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md, 02-05-SUMMARY.md, 02-06-SUMMARY.md, 02-07-SUMMARY.md, 02-08-SUMMARY.md]
started: 2026-09-28T08:33:52Z
updated: 2026-09-28T08:33:52Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Cold Start Smoke Test
expected: |
  Uninstall the app (or clear its data) on the Android emulator, then run `flutter run -d emulator-5554`. The app launches to the normal shell screen (not the "database/JS engine failed" recovery screen), and the log shows no JsBridgeException or bundle load error.
awaiting: user response

## Tests

### 1. Cold Start Smoke Test
expected: Fresh install via `flutter run -d emulator-5554` launches to the normal shell screen, not the recovery screen; no JsBridgeException / bundle load error in the log.
result: [pending]

### 2. JS bundle rebuilds reproducibly
expected: `bash tool/gen_js_bundle.sh` succeeds, and afterwards `git status --short assets/js third_party/opengym` shows no changes (byte-identical bundle, SHA-256 f454c4a2…).
result: [pending]

### 3. Parity fixtures regenerate deterministically
expected: `bash tool/gen_js_fixtures.sh` passes its 3-timezone gate (UTC, Asia/Kolkata, America/Los_Angeles) and `git status --short tool/fixtures tool/parity` shows no changes.
result: [pending]

### 4. Parity passes on Android (QuickJS)
expected: `bash tool/run_parity.sh emulator-5554` ends with `PARITY RESULT: PASS 167/167 engine=QuickJS openGym=1.3.8` and exits 0.
result: [pending]

### 5. Parity passes on iOS Simulator (JavaScriptCore)
expected: `bash tool/run_parity.sh <simulator-udid>` ends with `PARITY RESULT: PASS 167/167 engine=JavaScriptCore openGym=1.3.8` and exits 0.
result: [pending]

### 6. JS-04 audit is clean
expected: `bash tool/js04_audit.sh` exits 0 and reports no hand-written 1RM / progression / plate math in Dart.
result: [pending]

### 7. Static analysis is clean
expected: `flutter analyze` reports "No issues found!".
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0

## Gaps

[none yet]
