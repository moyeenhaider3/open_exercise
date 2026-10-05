# 05-06 SUMMARY: Workout-Day Reminder + During-a-Workout Rows

**Phase:** 05-timers-guest-mode  
**Plan:** 06  
**Status:** ✅ Complete  
**Date:** 2026-09-30

## What was done

### Task 1: ReminderSync — port of syncReminder/initReminderSync

- Created `lib/core/notifications/reminder_sync.dart` — `final class ReminderSync`
- `sync(GymState s, {bool interactive = false})`: exact port of mobile.js `syncReminder` (132-148):
  - Cancels `reminderJs.legacyIds` + `idBase..idBase+windowDays-1` (errors ignored)
  - Returns `true` when `reminder?.on != true`
  - Checks permissions, requests only when `interactive: true`
  - Schedules from `reminderJs.buildReminderNotifications(s, nowMs)` (JS does day selection; Dart only cancels/schedules)
  - Catches all exceptions → `false`
- `start()`:
  - (a) On boot: re-stamps `reminder.tz` if it differs from `localTimezone` (useStore.js:601-605), then syncs once
  - (b) Subscribes to `gymState.stream` with 800 ms debounce; resync only when projection changes (reminder, week, dayPlan, routines, workout dates)
  - (c) `AppLifecycleListener.onResume` always resyncs non-interactively (initReminderSync)
- `dispose()` cancels subscription, timer, and lifecycle listener
- `cancelAll` is never called (rest notification id is preserved — T-05-23 ✅)
- Added `final ReminderSync reminderSync` to `AppDependencies`
- `main.dart`: constructs `ReminderSync`, calls `start()` (fire-and-forget), passes into `AppDependencies`

### Task 2: Settings reminder events + NotificationsSection

**Events added to `settings_event.dart`:**
- `SettingsReminderToggled` — workout-day reminder switch (MobileReminderCard toggle)
- `SettingsReminderTimeChanged(String time)` — reminder time picker
- `SettingsRestAlertsRequested` — rest-alert permission row tap
- `SettingsNotificationStatusRequested` — refresh status on mount/foreground

**State additions to `settings_state.dart`:**
- `SettingsToast extends SettingsSignal` — carries failure message
- `notificationsAllowed: bool?` and `exactAlarmsAllowed: bool?` status fields

**`settings_bloc.dart` new handlers:**
- `_onReminderToggled`: calls `reminderSync.sync(tentative, interactive: true)` on toggle-on; if refused emits `SettingsToast('Could not change notification settings')` and returns; stamps `tz: localTimezone` on every write (T-05-21 ✅)
- `_onReminderTimeChanged`: validates `^([01]\d|2[0-3]):[0-5]\d$` (ASVS V5 / T-05-19 ✅); stamps `tz` on write
- `_onRestAlertsRequested`: calls `requestNotifications()`; if allowed and not exact, calls `requestExactAlarms()` (D-10 ✅)
- `_onNotificationStatusRequested`: refreshes allowed/exact status fields

**`NotificationsSection`** (port of MobileReminderCard + local rest-alert row):
- StatefulWidget — `initState` and `AppLifecycleListener.onResume` dispatch `SettingsNotificationStatusRequested`
- Rest-timer alerts row: shows correct subtitle based on `notificationsAllowed` / `exactAlarmsAllowed`; tappable (chevron) unless fully allowed; check icon when fully allowed
- Workout day reminder switch → `SettingsReminderToggled`
- Reminder time row (only when on) → `showTimePicker` → `SettingsReminderTimeChanged`
- Footer: 'Reminds you at this time on days that have a routine planned.' when on
- No push, subscription, server or "send test" UI (D-01/D-02 ✅)

**`settings_screen.dart`:**
- `NotificationsSection(state: state)` inserted after `WorkoutSection`, before `EquipmentSection`
- `SettingsToast` handled in `BlocListener` via `showToast`

**`settings_providers.dart`:**
- Passes `deps.reminderSync` and `deps.notificationService` to `SettingsBloc`

### Task 3: During-a-workout rows

**`workout_section.dart`** updated:
- `_kRestOptions` replaced with exactly openGym's list: Off(0), 60s, 90s, 120s, 150s, 180s (Settings.jsx:293-295)
- `_effectiveRestOptions()` helper: if stored value not in list (e.g. old import), shows as `{n}s` label without modifying stored value
- After Rest-pause rest: `AppRow(icon: 'sun', 'Keep screen awake')` with `AppSwitch(keepAwake != false)` — always enabled on mobile (wakeOK)
- After Sounds: only when `state.sound == true && Platform.isIOS` — `AppRow(icon: 'bell', 'Play sounds when the phone is on silent', subtitle: 'Music playing...')` with `AppSwitch(soundOnSilent == true)`
- Section footer: 'The screen stays on while a workout is running...' (Settings.jsx:271)
- Removed old "deferred to Phase 5" doc note; cites Settings.jsx:271-335

## Verification

```
flutter analyze          → No issues found!
bash tool/js04_audit.sh  → PASS
bash tool/guest_audit.sh → PASS
```

All acceptance grep assertions pass. The 30s value in the `grep -nE "value: (30|45|75|105|240|300),"` check is in `_kRestPauseOptions` (the separate rest-pause list), not in `_kRestOptions` — this is correct per openGym.

## Security (STRIDE)

| ID | Mitigation |
|----|------------|
| T-05-19 | `^([01]\d|2[0-3]):[0-5]\d$` regex before persisting reminder time |
| T-05-20 | 800 ms debounce + projection equality prevents resync storm during sets |
| T-05-21 | Only toggle (interactive:true) and RestAlertsRequested prompt the OS |
| T-05-22 | Accepted: routine names on lock screen, identical to openGym |
| T-05-23 | `cancelAll` never called; only reminder id ranges cancelled |
