# Phase 5 Plan 04 Summary: Platform Services (Notifications, Sound, Wakelock)

**Execution Date:** 2026-09-30  
**Phase:** 05-timers-guest-mode  
**Plan:** 05-04 (Wave 2)  
**Status:** Completed  

---

## 1. What was built

1. **`lib/core/notifications/notification_service.dart`**:
   - Encapsulates `flutter_local_notifications` and `timezone` configuration.
   - Initialises IANA time zone using `flutter_timezone`, defaulting safely to `UTC` on error.
   - Non-interactive init with `requestAlertPermission: false`, `requestBadgePermission: false`, `requestSoundPermission: false`.
   - Android channels: `rest-timer` (high importance) and `workout-reminder` (default importance).
   - `scheduleRestOver(int endsAtMs)` using `kRestNotificationId = 1`, title `Rest over — next set!` without body.
   - Exact/inexact fallback: uses `AndroidScheduleMode.exactAllowWhileIdle` when `canScheduleExact()` is true, falls back to `inexactAllowWhileIdle` if denied or if a `PlatformException` is thrown.
   - Reminder scheduling: `scheduleReminder(ReminderNotification n)` and `cancelIds(Iterable<int> ids)`.
   - Safe `NotificationService.disabled()` fallback that never throws.

2. **`lib/core/sound/timer_sound.dart`**:
   - Wraps `audioplayers` (6.8.1) and `vibration` (3.2.1).
   - Preloads 6 deterministic tone WAVs keyed by `${freq}_${ms}` in `PlayerMode.lowLatency`.
   - Non-focus audio context on Android (`usageType: assistanceSonification`, `audioFocus: none`).
   - Dynamic iOS audio session category switching: `AVAudioSessionCategory.playback` (mixWithOthers) when `soundOnSilent` is true, `AVAudioSessionCategory.ambient` when false.
   - `beep(bool enabled, int freq, double dur, [double when = 0])` and `vibrate(Object pattern)`.
   - `bind(GymStateCubit cubit)` reactive binding to `state.soundOnSilent`.
   - Safe `TimerSound.silent()` fallback.

3. **`lib/core/wakelock/wakelock_sync.dart`**:
   - Screen wake lock sync via `wakelock_plus`: `wanted = state.active != null && state.keepAwake != false`.
   - Reacts to `GymStateCubit` changes and `AppLifecycleListener.onResume`.
   - Silently swallows low-power mode refusal without throwing.

4. **Composition Root Wiring (`lib/app/dependencies.dart`, `lib/app/app.dart`, `lib/main.dart`)**:
   - `AppDependencies` holds `notificationService` and `timerSound`.
   - Provided into widget tree via `RepositoryProvider`.
   - `main.dart` initialises services with try/catch fallbacks (`disabled()`, `silent()`), binds audio session and starts `WakelockSync`.
   - `ApiClientFactory` preserved untouched as guest-only stub.

---

## 2. Verification

- `flutter analyze`: clean (0 issues).
- `tool/js04_audit.sh`: PASS.
- `tool/guest_audit.sh`: PASS.
- Automated grep assertion check: PASS (all criteria matched).

---

## 3. Next Steps

- Proceed to Plan 05-05: UI Timers (`WorkoutTimerBloc`, `RestTimerBar`, `TimerFlash`).
