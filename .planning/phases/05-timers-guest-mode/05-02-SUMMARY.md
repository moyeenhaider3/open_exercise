# Phase 05 Plan 02 Summary: Bridge supersetFlow.js & mobile.js reminder functions, facades, fixtures, device parity

**Completed Date**: 2026-09-30
**Execution Type**: autonomous

## Summary of Accomplishments

1. **Vendored supersetFlow.js**:
   - Added `supersetFlow.js` to `tool/gen_js_bundle.sh`'s `FILES` array.
   - Synced from `../openGym/frontend/src/lib/supersetFlow.js` (openGym v1.3.8).
   - Validated integrity via `third_party/opengym/lib/MANIFEST.sha256`; confirmed zero drift in other vendored files.

2. **Reminder Shim**:
   - Transcribed `REMINDER_WINDOW_DAYS` (60), `REMINDER_ID_BASE` (1000), `LEGACY_REMINDER_IDS` (100..106) and `buildReminderNotifications(S, nowMs)` from `../openGym/frontend/src/lib/mobile.js` lines 88–126 into `tool/js/shims/reminder-shim.js`.
   - Added `reminderDays(S, nowMs)` projection dropping timezone-dependent `schedule.at` for timezone-deterministic parity fixtures.

3. **Bridge & Rebuilt Bundle**:
   - Exported namespaces in `tool/js/entry.js`: `supersetFlow` and `reminder`.
   - Updated `tool/js/bridge-inventory.mjs` registering functions (`restAfterSet`, `restOnRecheck`, `restSecFor`, `warmupRestSecFor`, `buildReminderNotifications`, `reminderDays`) and constants.
   - Rebuilt `assets/js/opengym-lib.bundle.js` with input audit passing (34 inputs, SHA-256: d56d80728c373343674347f131aed86c883a27f38632a03c1311d747b6d9f87d).

4. **Deterministic Fixtures**:
   - Created 26 test cases in `tool/js/fixture-cases/phase5.mjs` covering all rest decision branches and reminder day calculations.
   - Generated fixtures under `TZ=UTC` and verified exact byte-level match under `TZ=Asia/Kolkata` and `TZ=America/Los_Angeles`.
   - Regenerated `tool/parity/parity_fixtures_data.dart`.

5. **Dart Facades & Models**:
   - `lib/core/js/models/phase5_models.dart`: `ReminderNotification` model.
   - `lib/core/js/modules/superset_flow_js.dart`: `SupersetFlowJs` facade and `engine.supersetFlow` getter.
   - `lib/core/js/modules/reminder_js.dart`: `ReminderJs` facade and `engine.reminder` getter.
   - Exported in `lib/core/js/opengym_js.dart`.

6. **Device Parity & Audits**:
   - Registered `phase5Dispatch` in `tool/parity/dispatch/phase5_dispatch.dart` and `tool/parity/parity_main.dart`.
   - `flutter analyze`: clean.
   - `bash tool/js04_audit.sh`: PASS.
   - `bash tool/run_parity.sh emulator-5554`: **PARITY RESULT: PASS 321/321** (QuickJS on Android 17 / API 37).
