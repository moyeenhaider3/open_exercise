# Phase 05 Plan 01 Summary: Legitimacy gate, packages install, native notification config, timer tone assets

**Completed Date**: 2026-09-30
**Execution Type**: checkpoint + auto

## Summary of Accomplishments

1. **Package Legitimacy Gate & Installation**:
   - Performed legitimacy audit and dependency resolution checks on `flutter_local_notifications`, `timezone`, `flutter_timezone`, `wakelock_plus`, `audioplayers`, and `vibration`.
   - Identified `equatable` v3 vs v2 constraint on `flutter_timezone >=5.0.0`; pinned `flutter_timezone: ^4.1.1` and `wakelock_plus: ^1.8.0` for full ecosystem compatibility.
   - User confirmed package identities at Task 1 checkpoint.
   - Added all 6 dependencies to `pubspec.yaml` (no dev/test packages added).
   - Documented dependencies in `NOTICE.md`.

2. **Android & iOS Native Configuration**:
   - Enabled `isCoreLibraryDesugaringEnabled = true` and `multiDexEnabled = true` with `desugar_jdk_libs:2.1.4` in `android/app/build.gradle.kts`.
   - In `android/app/src/main/AndroidManifest.xml`: added permissions for `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, and `VIBRATE`. Ensured `USE_EXACT_ALARM` and `INTERNET` are NOT declared per D-02 and D-10. Registered `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` with boot intent filters.
   - In `ios/Runner/AppDelegate.swift`: configured `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate`.

3. **Deterministic Audio Tone Assets**:
   - Implemented `tool/js/gen-timer-tones.mjs` reproducing the exact WebAudio gain envelope and frequency/duration pairs from openGym's `sound.js` and call sites:
     - `tone_660_100.wav`: 660 Hz @ 0.10s (countdown tick)
     - `tone_880_150.wav`: 880 Hz @ 0.15s (rest/work over, finish 1)
     - `tone_1320_400.wav`: 1320 Hz @ 0.40s (rest/work over final)
     - `tone_1040_120.wav`: 1040 Hz @ 0.12s (set checked)
     - `tone_1100_150.wav`: 1100 Hz @ 0.15s (workout finish 2)
     - `tone_1320_300.wav`: 1320 Hz @ 0.30s (workout finish 3)
   - Created bash wrapper `tool/gen_timer_tones.sh`.
   - Verified byte-identical deterministic output across repeated runs.
   - Added `- assets/audio/` to `pubspec.yaml`.

4. **Build Verification**:
   - `flutter analyze`: clean (0 issues).
   - `flutter build apk --debug`: succeeded (`build/app/outputs/flutter-apk/app-debug.apk`).
   - `flutter build ios --debug --no-codesign`: succeeded (`build/ios/iphoneos/Runner.app`).
