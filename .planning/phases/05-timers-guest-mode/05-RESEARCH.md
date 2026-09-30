# Phase 5: Timers & Guest Mode - Research

**Researched:** 2026-09-30
**Domain:** Flutter local notifications (exact alarms), screen wake lock, short-tone audio/haptics, guest-only (no-server) app verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Phase Boundary

Phase 5 delivers:
- The in-app rest timer with sound, flash and wakelock, matching openGym settings (TMR-01)
- An exact local notification when rest ends while the app is backgrounded; returning or skipping cancels it (TMR-02)
- A daily workout reminder (time + timezone) as a local notification (TMR-03)
- Guest-only operation: the app runs fully with no account and no server (AUTH-05)

Phase 5 does NOT deliver: server URL setup, passkey sign-in, pairing codes, logout, or any online sync.
Those parts (AUTH-01..04, SYNC-01..03) were removed from v1 by the user on 2026-09-30.

### Locked Decisions & Claude's Discretion

### Guest mode (locked)
- **D-01:** Guest mode is the ONLY mode. There is no sign-in screen, no server URL field, no account section,
  and no logout. Where openGym shows server/account/sync UI (Login, SyncBanner, Settings account
  rows, server-only buttons), the port hides it or replaces it with a local equivalent.
- **D-02:** No user data leaves the device. No network calls for user data (no `/api/data`, `/api/push/*`, etc.).
- **D-03:** Guest behaviour follows openGym's `lib/guest.js` wherever that logic applies to a no-server app.
- **D-04:** `flutter_passkey_service` is no longer used in v1. Do not add it in this phase.

### Timers & notifications (locked)
- **D-05:** Keep TMR-01..03 in this phase, as on the original roadmap.
- **D-06:** Use `flutter_local_notifications` (user-mandated) for the rest-end and daily reminder
  notifications. openGym's web push (`push.js`, `/api/push/rest-timer`) becomes local notifications.
- **D-07:** Timer numbers, sound choice and flash follow openGym (`RestTimer.jsx`, `TimerFlash.jsx`, `sound.js`).

### Phase 6 hand-off (for awareness, not planned here)
- **D-08 [informational]:** Phase 6 becomes Local Backup & Restore: periodic full-state JSON backups to a user-chosen device
  folder, a manual backup in Settings, and a full restore from a backup file (the backup is the
  master copy, like signing in again after a logout). Phase 5 must not build anything that
  assumes a server, so Phase 6 can add its Settings section cleanly.

### Claude's Discretion
- Exact-alarm permission handling on Android 12+/14 (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) and
  iOS notification permission prompts, with a graceful fallback when permission is denied.
- The wakelock mechanism and where timer state lives (Bloc layout per project conventions).
- How server-only openGym UI is hidden (removed routes vs hidden rows), as long as no dead
  server UI is reachable.

### Deferred Ideas (OUT OF SCOPE)

- Local backup & restore (Phase 6).
- Phase 7 (Coach & Admin) depends on a server in openGym; its scope needs a decision before Phase 7 planning.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TMR-01 | The in-app rest timer counts down with sound, flash and wakelock, matching openGym settings | `useUI.js`/`RestTimer.jsx`/`TimerFlash.jsx`/`wakelock.js` behavior fully documented (Summary, Architecture Patterns, Code Examples); `wakelock_plus`/`audioplayers`/`vibration` selected and version-verified; existing `GymState` settings fields (`restSec`, `restPauseSec`, `sound`, `soundOnSilent`, `timerFlash`, `keepAwake`) already modeled — see Standard Stack, Don't Hand-Roll, Open Question 1 (work/hold timer scope) |
| TMR-02 | If the app is backgrounded during rest, an exact local notification fires when the rest ends; returning or skipping cancels it | `flutter_local_notifications` `zonedSchedule`/`AndroidScheduleMode.exactAllowWhileIdle`, exact-alarm permission handling (Pitfall 2), and cancel-on-stopRest requirement (Pitfall 4) documented |
| TMR-03 | User can set a daily workout reminder (time + timezone) that fires as a local notification | `mobile.js` `buildReminderNotifications`/`syncReminder` port pattern (Architecture Patterns Pattern 2, Pitfall 1); `timezone`/`flutter_timezone` package selection for TZ correctness (Pitfall 5); existing `Reminder` model already in `GymState` |
| AUTH-05 | User can use the app as a guest/offline with no account (the only mode in v1) | Verified via codebase inspection that no Login/SyncBanner/account UI exists and `ApiClientFactory.create()` is never called at runtime (Summary, Open Question 3, Security Domain) — this phase is primarily a verification task for AUTH-05, not new construction |
</phase_requirements>

## Summary

Phase 5 has two halves that are very different in size. The **guest-mode half (AUTH-05) is
almost entirely already done**: the app has no Login view, no SyncBanner, no account/server
routes, and the one `ApiClientFactory` in the DI graph is a `const` factory whose `.create()`
method is never called anywhere in the codebase — no `Dio` instance is ever constructed at
runtime, so there are already no network calls for user data. Settings already states "No
account, no cloud." The Phase 5 work here is mostly **verification** (grep/CLI assertions that
this stays true) plus a couple of small cleanups, not new UI.

The **timer half (TMR-01..03) is a real, from-scratch build.** Phase 3's `WorkoutBloc` explicitly
deferred both the rest timer and the work/hold timer with `// D-02: rest timer is Phase 5
TMR-01` markers at every trigger point (`active` == exercise progress logic in
`lib/features/workout/bloc/workout_bloc.dart`), and there is currently no rest-timer bar, no
work/hold-timer bar, no beep/vibrate/flash, no wakelock, and no reminder scheduling anywhere in
the Flutter app. All the settings *data* fields these features read/write already exist on
`GymState` (`restSec`, `restPauseSec`, `sound`, `soundOnSilent`, `timerFlash`, `keepAwake`,
`reminder`) and are already wired through `SettingsBloc`/`SettingsEvent` for the rows that exist
today (`restSec`, `restPauseSec`, `sound`, `timerFlash`) — `keepAwake`, `soundOnSilent`, and
`reminder` have model + event plumbing but **no Settings UI row yet**.

openGym's own Capacitor/mobile build (`lib/mobile.js`, `VITE_MOBILE=1`) is the correct behavioral
reference for the reminder, not the web-push code in `lib/push.js`/`views/Settings.jsx`
`PushCard`: `mobile.js`'s `buildReminderNotifications`/`syncReminder` and
`Settings.jsx`'s `MobileReminderCard` show exactly the no-server, local-notification pattern this
phase should port (one-off notifications per future planned day, not repeating-daily — see
Pitfall 1). `push.js`/`PushCard` are the server/VAPID web-push variant and should be ignored
entirely (AUTH-01..04/SYNC out of scope).

**Primary recommendation:** Build the rest+work timer as a `TimerCubit`/mixin inside (or
alongside) `WorkoutBloc` state, replacing every `// D-02` comment with real `startRest`/`addRest`/
`stopRest`/`startWork`/`finishWorkEarly`/`stopWork` logic (1:1 with `useUI.js`); wire
`flutter_local_notifications` + `timezone`/`flutter_timezone` for TMR-02 (fire-on-background,
cancel-on-return/skip) and TMR-03 (native local reminder ported from `mobile.js`, not web push);
add `wakelock_plus` for `keepAwake`; add one small audio package (`audioplayers`, playing
pre-rendered tone assets — Dart cannot synthesize a live oscillator the way `sound.js`'s
WebAudio code does) plus `vibration` for the exact `[200,100,200]` pattern (Flutter's built-in
`HapticFeedback` cannot do custom multi-pulse patterns). For AUTH-05, add a CLI/grep verification
step asserting no runtime `ApiClientFactory.create(` call site and no login/account route exists,
and leave the generated Dio/OpenAPI client code in place (FND-02, out of scope to remove; already
inert).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rest/work countdown state (left/total/endsAt) | App logic (Bloc/Cubit, Dart) | — | Pure timing state; not domain math, no JS-04 concern — openGym itself keeps this in `useUI.js` (UI store), not `lib/*.js` |
| Beep tone generation/playback | Browser/Client equivalent → native audio plugin | Build-time asset generation (tool script) | No live oscillator API in Dart; pre-rendered WAV assets + a playback plugin replace WebAudio |
| Haptic vibration pattern | Native platform (via plugin) | — | Custom multi-pulse pattern needs a plugin; `HapticFeedback` alone is insufficient |
| Screen wake lock | Native platform (via plugin) | — | `wakelock_plus` wraps Android `FLAG_KEEP_SCREEN_ON` / iOS `isIdleTimerDisabled` |
| Backgrounded rest-end alert | OS notification tray (via `flutter_local_notifications`) | App logic (schedule/cancel) | Must survive the app being backgrounded/suspended; in-process `Timer` cannot guarantee firing |
| Daily workout reminder | OS notification tray (via `flutter_local_notifications`) | App logic (rebuild schedule from `S.reminder`/`S.week`/`S.dayPlan`) | No server; local-only, mirrors openGym's own `mobile.js` (not `push.js`) |
| Guest-only enforcement (no login/account UI, no network calls) | App logic (DI graph, router) | Verification tooling (grep/CLI) | Already structurally absent; this phase is mostly an audit, not new UI |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_local_notifications` | 22.3.1 (published 2026-09-13) [VERIFIED: pub.dev registry] | TMR-02 exact rest-end alert, TMR-03 daily reminder | User-mandated in CLAUDE.md; the de-facto standard local-notification plugin for Flutter (7350 pub.dev likes, 150/160 pub points) |
| `timezone` | 0.11.1 (2026-06-29) [VERIFIED: pub.dev registry] | `TZDateTime` required by `zonedSchedule` | Direct dependency of `flutter_local_notifications`'s scheduling API; must be added and `initializeTimeZones()` called explicitly per current docs |
| `flutter_timezone` | 5.1.0 (2026-05-28) [VERIFIED: pub.dev registry] | Read the device's IANA timezone name (openGym's `localTZ()` equivalent) | Actively maintained fork of the abandoned `flutter_native_timezone`; needed so `S.reminder.tz` matches openGym's "re-stamp tz on every load" behavior |
| `wakelock_plus` | 1.8.1 (2026-09-29) [VERIFIED: pub.dev registry] | TMR-01 `keepAwake` — screen stays on during rest, matches `S.keepAwake` | Successor to the unmaintained `wakelock`; 160/160 pub points, published the day before this research |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `audioplayers` | 6.8.1 (2026-06-27) [VERIFIED: pub.dev registry] | Play pre-rendered short WAV tone assets for the timer beeps | Dart/Flutter has no built-in oscillator/tone-synthesis API; a lightweight SFX player is the standard substitute for `sound.js`'s WebAudio beeps |
| `vibration` | 3.2.1 (2026-09-02) [VERIFIED: pub.dev registry] | Custom multi-pulse pattern `[200, 100, 200]` matching `vibrate()` calls in `sound.js`/`useUI.js` | Flutter's built-in `HapticFeedback` only exposes fixed impact styles, not a custom on/off millisecond pattern |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `audioplayers` | `just_audio` (0.10.6) | `just_audio` is heavier (built for streaming/playlists); `audioplayers` is the lighter, more common choice for one-shot SFX and is what most Flutter "beep on event" tutorials use |
| `audioplayers` | Platform channel to native `ToneGenerator`/`AudioServicesPlaySystemSound` | Avoids a dependency entirely but requires hand-written Kotlin/Swift platform code per project (higher effort, harder to keep 1:1 with openGym's exact frequencies without more native code) |
| `vibration` | Flutter's built-in `HapticFeedback.vibrate()` | Only a single fixed-duration buzz — cannot reproduce the `[200,100,200]` pattern; rejected |
| `flutter_timezone` | `iana_time_zone` | Both are small, single-purpose plugins; `flutter_timezone` was chosen as the explicitly-maintained fork lineage (`flutter_native_timezone` → `flutter_timezone`) with slightly higher likes |

**Installation:**
```bash
flutter pub add flutter_local_notifications timezone flutter_timezone wakelock_plus audioplayers vibration
```

**Version verification:** Verified live via `curl https://pub.dev/api/packages/<pkg>` (returns
`latest.version` / `latest.published`) on 2026-09-30 — see table above for exact versions and
dates. This is the Dart/Flutter-ecosystem equivalent of `npm view`/`pip index versions` (pub.dev
is the canonical registry; there is no separate CLI registry tool for Dart).

## Package Legitimacy Audit

`slopcheck` targets the npm/PyPI ecosystem and could not be installed in this environment (`pip`
itself is not present: `command not found: pip`). Dart/Flutter packages were instead
cross-checked directly against the pub.dev registry API (`/api/packages/<pkg>` and
`/api/packages/<pkg>/score`), which is the authoritative source of truth for this ecosystem —
but per the package-name provenance rule, **discovery still happened via WebSearch/training
knowledge**, so every package below is tagged `[ASSUMED]` and the planner must gate each
`flutter pub add` behind a `checkpoint:human-verify` task, per the graceful-degradation rule.

| Package | Registry | Pub Points | Likes | Source Repo | slopcheck | Disposition |
|---------|----------|-----------|-------|--------------|-----------|-------------|
| `flutter_local_notifications` [ASSUMED] | pub.dev | 150/160 | 7350 | github.com/MaikuB/flutter_local_notifications | not run (unavailable) | Approved — user-mandated in CLAUDE.md regardless |
| `timezone` [ASSUMED] | pub.dev | 160/160 | 594 | github.com/dart-lang (dart_org) | not run (unavailable) | Approved, checkpoint recommended |
| `flutter_timezone` [ASSUMED] | pub.dev | 150/160 | 342 | github.com/xavidop/flutter_timezone | not run (unavailable) | Approved, checkpoint recommended |
| `wakelock_plus` [ASSUMED] | pub.dev | 160/160 | 645 | github.com/fluttercommunity/wakelock_plus | not run (unavailable) | Approved, checkpoint recommended |
| `audioplayers` [ASSUMED] | pub.dev | 150/160 | 3445 | github.com/bluefireteam/audioplayers | not run (unavailable) | Approved, checkpoint recommended |
| `vibration` [ASSUMED] | pub.dev | 160/160 | 940 | github.com/benjamindean/flutter_vibration | not run (unavailable) | Approved, checkpoint recommended |

**Packages removed due to slopcheck [SLOP] verdict:** none — slopcheck did not run.
**Packages flagged as suspicious [SUS]:** none identified by pub.dev metrics (all have healthy
pub points/likes and known source repos), but all are `[ASSUMED]` per the graceful-degradation
rule above; the planner must insert a `checkpoint:human-verify` before each `flutter pub add`.

## Architecture Patterns

### System Architecture Diagram

```
Set checked (WorkoutBloc._onSetChecked)
        │
        ▼
progression/unit-done? ──no──> (no timer)
        │yes
        ▼
TimerController.startRest(sec, forIdx)         TimerController.startWork(sec, label, onDone)
        │                                             │  (timed/'time'-mode sets — hold countdown)
        ▼                                             ▼
in-process 1s ticker (Dart Timer.periodic)   same ticker, mutually exclusive with rest
        │  while app foregrounded: tick UI bar, beep@<=3s
        │
        ├── app backgrounded (AppLifecycleListener onHide/onPause) ─────┐
        │                                                                ▼
        │                                                    flutter_local_notifications
        │                                                    .zonedSchedule(rest-end, exact)
        ▼                                                                │
left == 0 while foregrounded:                                            │
  beep x3 (audioplayers) + vibrate([200,100,200])                        │
  + flashTimer() (theme blink) + toast                                   │
        │                                                                │
        └──────────────── returning to foreground / Skip pressed ────────┘
                                   │
                                   ▼
                     cancel any pending rest-end notification (TMR-02)

Settings: reminder.on/time toggled
        │
        ▼
SettingsBloc → GymStateCubit.mutate(reminder: ...)
        │
        ▼
ReminderScheduler.sync(S)  (ported from mobile.js buildReminderNotifications/syncReminder)
        │
        ▼
flutter_local_notifications: cancel old IDs, schedule one-off notifications
per future planned day (bounded window), using flutter_timezone for tz stamping (TMR-03)
```

### Recommended Project Structure
```
lib/core/notifications/
├── notification_service.dart      # thin wrapper: init, requestPermission, zonedSchedule, cancel
├── reminder_scheduler.dart        # port of mobile.js buildReminderNotifications/syncReminder
lib/core/wakelock/
├── wakelock_service.dart          # thin wrapper over wakelock_plus, mirrors lib/wakelock.js API
lib/core/sound/
├── timer_sound.dart                # beep()/unlock()/vibrate() port, using audioplayers + vibration
lib/features/workout/bloc/
├── timer_controller.dart          # rest+work countdown state machine (port of useUI.js timer/work slice)
lib/features/workout/view/widgets/
├── rest_timer_bar.dart             # port of RestTimer.jsx
├── timer_flash_overlay.dart        # port of TimerFlash.jsx
assets/audio/
├── beep_880.wav, beep_1320.wav, beep_660.wav   # pre-rendered tones (generated by a tool/ script)
tool/
├── gen_timer_tones.{sh,py}         # generates the WAV assets deterministically (checked in output)
```

### Pattern 1: Rest/Work Timer State Machine (port of `useUI.js`)
**What:** A single controller owning `timer` (rest) and `work` (timed-set hold) state, mutually
exclusive by construction (`startWork` calls `stopRest`; `startRest` implicitly assumes no work
is running).
**When to use:** Every call site currently marked `// D-02: rest timer is Phase 5 TMR-01` in
`lib/features/workout/bloc/workout_bloc.dart`.
**Example (ported logic, not literal openGym code — Dart has no direct source to cite):**
```dart
// Source: behavior ported from ../openGym/frontend/src/store/useUI.js lines 90-145
void startRest(int sec, int? forIdx) {
  stopRest();
  if (sec <= 0) return; // "Off" setting — matches useUI.js:92-94
  final endsAt = DateTime.now().add(Duration(seconds: sec));
  emit(state.copyWith(timer: RestTimerState(left: sec, total: sec, endsAt: endsAt, forIdx: forIdx)));
  _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  _scheduleBackgroundNotification(sec); // TMR-02: flutter_local_notifications.zonedSchedule
}
```

### Pattern 2: Reminder Sync (port of `mobile.js`)
**What:** `syncReminder(S, interactive)` cancels the whole reminder notification ID window and
re-schedules one-off notifications for each future planned day within a bounded window (openGym
uses `REMINDER_WINDOW_DAYS = 60`), skipping days already logged (`S.workouts`).
**When to use:** On every settings change to `reminder`/`week`/`dayPlan`, and on app foreground
resume (`AppLifecycleListener.onResume` or `onShow`).
**Example:**
```dart
// Source: behavior ported from ../openGym/frontend/src/lib/mobile.js
// buildReminderNotifications (lines 96-126) and syncReminder (lines 132-148)
Future<bool> sync(GymState s, {bool interactive = false}) async {
  await _plugin.cancelAll(); // or cancel exact ID range, mirroring REMINDER_ID_BASE window
  final r = s.reminder;
  if (r == null || r.on != true) return true;
  var perm = await _plugin.resolvePlatformSpecificImplementation<...>()?.areNotificationsEnabled();
  if (perm != true && interactive) perm = await _requestPermission();
  if (perm != true) return false;
  for (final n in buildReminderNotifications(s, DateTime.now())) {
    await _plugin.zonedSchedule(n.id, n.title, n.body, n.scheduledDate, _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }
  return true;
}
```
**Important divergence from `mobile.js`:** openGym's mobile build schedules one **one-off**
notification per future calendar date (not a single repeating daily alarm) precisely because a
day with no routine planned must be silently skipped, and completed days must be suppressed. Do
**not** implement TMR-03 with `matchDateTimeComponents` daily-repeat alone — that would fire every
day regardless of the plan/completion state, diverging from openGym (see Pitfall 1).

### Anti-Patterns to Avoid
- **A single repeating `matchDateTimeComponents: DateTimeComponents.time` daily alarm for
  TMR-03:** matches the naive reading of "daily reminder" but does not match openGym's actual
  behavior of skipping days with no planned routine or an already-logged workout. Port the
  bounded one-off-per-day window from `mobile.js` instead.
- **Driving the rest/work countdown purely from a background-scheduled notification:** the
  in-app bar must still count down live while foregrounded (openGym's `timerTick`/`workTick`);
  the notification is only the backgrounded fallback (TMR-02), not a replacement for the
  foreground UI.
- **Putting beep/vibrate/plate-math-adjacent timing logic in the JS bridge:** `useUI.js` (the UI
  store) is explicitly *not* one of the `lib/*.js` domain modules bundled for JS-04 — it is React
  state/effect glue. Timer countdown state belongs in Dart (Bloc/Cubit), matching where openGym
  itself keeps it. Do not attempt to bridge this into QuickJS.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exact-time alarm that survives backgrounding | A `Timer`/`Future.delayed` that fires after the app resumes | `flutter_local_notifications.zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle` | Dart timers are suspended when the process is backgrounded/killed by the OS; only an OS-level alarm guarantees delivery |
| Custom vibration pulse sequencing | Manual `Future.delayed` chains calling `HapticFeedback` repeatedly | `vibration` package's pattern API | Handles device capability checks (`hasVibrator`, amplitude support) and exact pattern timing correctly across OEMs |
| Device IANA timezone detection | Parsing `DateTime.now().timeZoneName`/offset heuristics | `flutter_timezone` | `DateTime.now().timeZoneName` gives an abbreviation (e.g. "PST"), not an IANA name (e.g. "America/Los_Angeles"); `zonedSchedule` needs a real IANA `Location` from the `timezone` package |
| Screen-stays-on behavior | Platform channel toggling `FLAG_KEEP_SCREEN_ON` / `isIdleTimerDisabled` by hand | `wakelock_plus` | Already handles visibility-change re-acquisition (same problem openGym's own `lib/wakelock.js` solves) and both platforms' APIs |

**Key insight:** Every "Don't Hand-Roll" item above is precisely the platform-integration surface
openGym's own vanilla-JS `lib/wakelock.js`/`lib/mobile.js`/`lib/sound.js` had to hand-roll for the
browser/Capacitor because no framework did it for them; Flutter's plugin ecosystem already
solves each one, so the port should consume the plugin rather than reproduce openGym's browser
workarounds (e.g. do **not** port the WebAudio "resume suspended AudioContext on tap" workaround
— it's a Safari-specific problem that does not exist in Flutter).

## Common Pitfalls

### Pitfall 1: Reminder implemented as a naive "fire every day at time X" alarm
**What goes wrong:** The reminder fires on days with no planned routine, or on days the user
already logged a workout — both diverge from openGym.
**Why it happens:** `matchDateTimeComponents: DateTimeComponents.time` (the obvious
flutter_local_notifications API for "daily reminder") only knows about time-of-day, not the
day's plan/completion state.
**How to avoid:** Port `buildReminderNotifications`/`syncReminder` from `mobile.js` verbatim in
spirit: schedule one one-off notification per future date within a bounded window (60 days in
openGym), re-synced (cancel + rebuild) on every state change to `reminder`/`week`/`dayPlan` and
on app foreground.
**Warning signs:** A device check where the reminder fires on a rest day, or fires again after
the user already logged that day's workout.

### Pitfall 2: Exact alarms silently downgraded on Android 12+
**What goes wrong:** `zonedSchedule` with `androidScheduleMode: AndroidScheduleMode.exact` throws
or silently becomes inexact if `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` isn't granted/declared,
so TMR-02's "exact notification at the end of rest" success criterion fails on real Android 12–15
devices even though it works on an emulator with the permission pre-granted.
**Why it happens:** Android 12 introduced `SCHEDULE_EXACT_ALARM` (must be requested at runtime via
`requestExactAlarmsPermission()` in `flutter_local_notifications` 16+), and Android 14 tightened
enforcement further; `USE_EXACT_ALARM` avoids the runtime prompt but signals "alarm clock"-style
use to Play policy review and requires `targetSdk >= 33`.
**How to avoid:** Declare `SCHEDULE_EXACT_ALARM` in `AndroidManifest.xml`, call
`requestExactAlarmsPermission()` before the first schedule attempt, and use
`AndroidScheduleMode.exactAllowWhileIdle`. Provide a graceful fallback (inexact scheduling or a
"permission needed" toast) if denied, per CONTEXT.md's "Claude's Discretion" note.
**Warning signs:** Rest-end notification arrives late (minutes off) or not at all on a physical
Android 13+ device while working fine on an older emulator image.

### Pitfall 3: iOS silent switch mutes the timer beep
**What goes wrong:** On a real iPhone with the ring/silent switch set to silent, the beep is
inaudible even though `sound: true` — reads as a bug at the gym exactly when it matters
(the same bug openGym's own code comment calls out, `sound.js` header comment, issue #152).
**Why it happens:** Default audio session categories respect the silent switch; only an
exclusive/"playback"-style session ignores it.
**How to avoid:** Ensure the chosen audio package's iOS session category (check `audioplayers`'s
`AudioContext`/session-category configuration) is set to a playback-style category when
`soundOnSilent` is on, mirroring openGym's opt-in `setPlayOnSilent` — off by default, matching
`DEF.soundOnSilent = false`.
**Warning signs:** Beeps work on Android and on iOS simulator (which has no silent switch) but
not on a real iPhone with the switch flipped.

### Pitfall 4: Notification not cancelled on Skip/return, leaving a stale alert
**What goes wrong:** User skips the rest or the app is reopened before rest ends, but the
scheduled background notification still fires later, confusing the user (TMR-02 explicitly
requires "returning or skipping cancels it").
**Why it happens:** The Dart in-process timer state (`stopRest()`) and the OS-level scheduled
notification are two separate systems; clearing one does not automatically clear the other.
**How to avoid:** Every path that calls `stopRest()` (skip, add/subtract making left <= 0, app
resume before the countdown naturally elapsed, `addRest` going negative) must also call
`flutter_local_notifications.cancel(id)` for that rest's notification id, mirroring openGym's
`cancelPushRestTimer()` call inside `stopRest()`.
**Warning signs:** A device check where skipping rest or reopening the app still produces a
notification a few seconds/minutes later.

### Pitfall 5: `timezone` package not initialized before first `zonedSchedule` call
**What goes wrong:** `zonedSchedule` throws or uses UTC/wrong offset if `tz.initializeTimeZones()`
and `tz.setLocalLocation(tz.getLocation(deviceTzName))` haven't run yet.
**How to avoid:** Initialize both in `NotificationService`'s startup (called from
`AppDependencies`/app boot), using `flutter_timezone` to resolve the actual IANA name, before any
scheduling call — including the very first reminder sync on cold boot.
**Warning signs:** Reminder fires at the wrong local time, especially for users outside UTC or
after DST transitions.

## Code Examples

### Rest timer settings already modeled in Dart (no new model work needed)
```dart
// Source: lib/core/models/gym_state.dart (existing code, Phase 1 FND-03)
// restSec, restPauseSec, sound, soundOnSilent, timerFlash, keepAwake, reminder
// are already fields on GymState with fromJson/toJson/copyWith — Phase 5 only
// needs to READ/WRITE them, not add them.
```

### Existing Phase-3 deferral markers to replace
```dart
// Source: lib/features/workout/bloc/workout_bloc.dart (existing code, ~line 1451-1474)
// D-02: rest timer is Phase 5 TMR-01
if (!progress.isNew) {
  // D-02: rest timer is Phase 5 TMR-01 (restOnRecheck omitted)
  return;
}
// ... four such comments mark every startRest/stopRest call site to restore.
```

### openGym's exact beep/vibrate/flash sequence to reproduce
```javascript
// Source: ../openGym/frontend/src/store/useUI.js lines 105-118 (also 169-181 for work timer)
if (left <= 0) {
  if (seenLive) {
    beep(snd, 880, 0.15); beep(snd, 880, 0.15, 0.25); beep(snd, 1320, 0.4, 0.5)
    vibrate([200, 100, 200]); get().flashTimer()
  }
  get().toast(t('Rest over — next set!'))
  maybeRestNotification(); get().stopRest(); return
}
if (left <= 3) beep(snd, 660, 0.1)
```
Three distinct tones must be reproduced as pre-rendered assets: 880Hz/0.15s (twice, second
delayed 0.25s), 1320Hz/0.4s (delayed 0.5s), plus a 660Hz/0.1s tick repeated whenever `left <= 3`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Android inexact `AlarmManager` scheduling assumed sufficient | `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` runtime-gated exact alarms | Android 12 (2021) tightened further in Android 13/14 | Must explicitly request permission and choose `AndroidScheduleMode.exactAllowWhileIdle`, with a non-exact fallback |
| `wakelock` package | `wakelock_plus` (fluttercommunity fork) | `wakelock` unmaintained; `wakelock_plus` is the active successor | Use `wakelock_plus`, not the legacy `wakelock` name |
| `flutter_native_timezone` | `flutter_timezone` (community fork) | `flutter_native_timezone` unmaintained | Use `flutter_timezone` |

**Deprecated/outdated:**
- `wakelock`: superseded by `wakelock_plus`; do not add the old package name.
- `flutter_native_timezone`: superseded by `flutter_timezone`; do not add the old package name.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `flutter_local_notifications` 22.3.1, `timezone` 0.11.1, `flutter_timezone` 5.1.0, `wakelock_plus` 1.8.1, `audioplayers` 6.8.1, `vibration` 3.2.1 are legitimate, safe-to-install packages | Standard Stack / Package Legitimacy Audit | Low — all verified against the pub.dev registry directly (version, publish date, pub points, likes, source repo) even though slopcheck itself could not run; planner should still checkpoint each install per protocol |
| A2 | `audioplayers` is the right choice over `just_audio`/a hand-written platform channel for the exact-frequency beep tones | Standard Stack / Alternatives Considered | Medium — if audioplayers' iOS session-category handling can't achieve the `soundOnSilent` "playback" behavior cleanly, a platform channel may be needed instead; verify during Wave 1 device checks |
| A3 | The rest/work timer & reminder should live in Dart app logic, not be bridged through QuickJS | Architecture Patterns | Low — matches openGym's own layering (`useUI.js`/`mobile.js` are UI-store/platform glue, not `lib/*.js` domain modules subject to JS-04) |
| A4 | The work/hold ("time"-mode set) timer is in scope for this phase, even though CONTEXT.md's Phase Boundary text only names the "rest timer" for TMR-01 | Summary / Open Questions | Medium — see Open Question 1; if the planner scopes it out, `WorkoutBloc`'s `time`-mode sets will keep firing "Hold logged" with no real countdown, an incomplete-feeling feature |

## Open Questions

1. **Is the work/hold timer (timed 'time'-mode sets, e.g. planks) in scope for Phase 5?**
   - What we know: `WorkoutBloc`'s header comment says "Per D-02, work **and rest** countdown
     timers are omitted and moved to Phase 5" (both are deferred together), and openGym's
     `RestTimer.jsx` renders both from one shared component/state slice. Today, checking a
     `time`-mode set in the Flutter app immediately shows a "Hold logged" toast with no actual
     countdown UI at all.
   - What's unclear: CONTEXT.md's `Phase Boundary` and TMR-01's requirement text mention only
     "the in-app rest timer," not the work/hold timer, by name.
   - Recommendation: Treat the work timer as in-scope (same `RestTimer.jsx`-equivalent widget,
     same beep/vibrate/flash, no background notification needed per openGym's own comment that a
     work set "is something you are watching") since it shares essentially all the same
     mechanics and code paths as the rest timer, and leaving it out would leave a half-finished
     UI-03 hold-logging flow. Flag this explicitly to the user during `/gsd:discuss-phase` or
     plan review if the planner disagrees.

2. **Exact vs. `USE_EXACT_ALARM` for TMR-02/TMR-03 on Android.**
   - What we know: `SCHEDULE_EXACT_ALARM` requires a runtime permission prompt (user-facing,
     revocable) while `USE_EXACT_ALARM` needs no prompt but "could be subject to approval and
     auditing" by Play Store review, per the plugin's own documentation.
   - What's unclear: Whether this app will ever be distributed via Play Store (vs. sideloaded) —
     not stated in CONTEXT.md/REQUIREMENTS.md.
   - Recommendation: Default to `SCHEDULE_EXACT_ALARM` + `requestExactAlarmsPermission()` (the
     safer, store-compliant path) with `exactAllowWhileIdle`, and fall back to inexact scheduling
     with a toast if the user declines — this was already flagged as "Claude's Discretion" in
     CONTEXT.md.

3. **Should the unused `ApiClientFactory`/generated Dio client code be removed in this phase, or
   left in place?**
   - What we know: It is fully inert today (never instantiated with `.create()` anywhere), so it
     already satisfies "no network calls for user data." FND-02 delivered it in Phase 1 and it is
     not called out as something Phase 5 must touch.
   - What's unclear: Whether leaving fully-generated-but-dead server API code in the repo is
     acceptable long-term, given AUTH-01..04/SYNC-01..03 are now permanently out of scope for v1.
   - Recommendation: Leave it in place for Phase 5 (out of scope to change per REQUIREMENTS.md's
     "Changes to the openGym server or API" being out of scope, and this isn't server code, it's
     the client — but removing/pruning it is a bigger call than this phase's boundary). Add a
     verification assertion (grep) that it stays uninstantiated, and surface the "should we
     delete `lib/core/api/generated` entirely" question to the user for a future phase/cleanup
     decision, not this one.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter/Dart SDK | Everything | ✓ | per `pubspec.yaml` (^3.13.2) | — |
| Android emulator/device for exact-alarm device checks | TMR-02/TMR-03 device verification | Unverified in this research session (no device probed) | — | Planner must schedule a `[device check]` wave per project convention (Phase 3/3.1/4 pattern) |
| iOS simulator/device for silent-switch/notification device checks | TMR-01 (soundOnSilent), TMR-02/03 permission prompts | Unverified in this research session | — | iOS Simulator cannot test the physical silent switch — Pitfall 3 needs a **real device** check, not just simulator |
| `pip`/`slopcheck` | Package Legitimacy Audit | ✗ (`pip` not found in this environment) | — | Verified packages manually via pub.dev API instead; planner adds `checkpoint:human-verify` per package |

**Missing dependencies with no fallback:**
- A real iOS device is required to verify Pitfall 3 (silent-switch behavior) and real
  notification permission prompts; the iOS Simulator does not have a physical silent switch.

**Missing dependencies with fallback:**
- `pip`/`slopcheck` — pub.dev registry API used instead (see Package Legitimacy Audit).

## Security Domain

`security_enforcement` is not present in `.planning/config.json` and defaults to enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Guest-only; no authentication surface exists or is added in this phase |
| V3 Session Management | No | No session state; nothing to manage |
| V4 Access Control | No | Single-user local device, no roles |
| V5 Input Validation | Yes | Reminder time input (`HH:mm`) must validate against malformed strings before persisting to `S.reminder.time`, matching `mobile.js`'s `Number.isInteger(hour)`/`Number.isInteger(minute)` guard |
| V6 Cryptography | No | No secrets/crypto introduced by this phase |
| V14 Configuration/Data Protection (adapted) | Yes | Notification payload text must not leak sensitive workout detail to the lock screen beyond what openGym itself shows (openGym's own reminder body includes routine names — acceptable, matches parity) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Regression reintroducing a network call for user data (e.g. a future contributor calls `ApiClientFactory.create()` for "convenience") | Information Disclosure | CLAUDE.md/AUTH-05 constraint enforced by a grep-based CI/verification assertion (`bash tool/…` style, no test files) that fails if `.create(` appears outside `lib/core/api/`; document the rule in a code comment at the `ApiClientFactory` definition |
| Overly broad `USE_EXACT_ALARM` requesting alarm-clock-level trust unnecessarily | Elevation of Privilege (policy) | Prefer `SCHEDULE_EXACT_ALARM` + runtime permission request; only use `USE_EXACT_ALARM` if the user later confirms Play Store distribution and accepts the review risk |
| Malformed reminder time string crashing the scheduler | Denial of Service (local) | Validate `HH:mm` before calling `zonedSchedule`, mirroring `mobile.js`'s `Number.isInteger` guard; skip scheduling (return empty list) rather than throw |

## Sources

### Primary (HIGH confidence)
- pub.dev registry API (`https://pub.dev/api/packages/<pkg>`, `.../score`) — versions, publish
  dates, pub points, likes for `flutter_local_notifications`, `timezone`, `flutter_timezone`,
  `wakelock_plus`, `audioplayers`, `vibration` (fetched 2026-09-30)
- `../openGym/frontend/src/store/useUI.js` — exact rest/work timer state machine, beep/vibrate/
  flash sequence and thresholds
- `../openGym/frontend/src/lib/mobile.js` — native reminder scheduling pattern
  (`buildReminderNotifications`/`syncReminder`), the correct reference for TMR-03 (not `push.js`)
- `../openGym/frontend/src/lib/sound.js`, `../openGym/frontend/src/lib/wakelock.js`,
  `../openGym/frontend/src/lib/guest.js` — sound/wakelock platform-quirk rationale, guest-mode
  server-config gating (mostly inapplicable — no server in this app)
- `../openGym/frontend/src/components/RestTimer.jsx`, `TimerFlash.jsx` — UI structure/behavior
- `../openGym/frontend/src/views/Settings.jsx` (During a workout section, `MobileReminderCard`) —
  exact settings rows and reminder UI to port
- Codebase inspection: `lib/features/workout/bloc/workout_bloc.dart` (D-02 deferral markers),
  `lib/core/models/gym_state.dart` (existing settings fields), `lib/features/settings/*`
  (existing rows), `lib/app/app.dart`/`dependencies.dart`/`lib/core/api/open_gym_api_client.dart`
  (confirmed `ApiClientFactory` is never instantiated with `.create()`), `lib/core/router/
  app_router.dart` (no login/admin routes), `android/app/src/main/AndroidManifest.xml`,
  `ios/Runner/Info.plist`/`AppDelegate.swift` (no notification/wakelock setup present yet)

### Secondary (MEDIUM confidence)
- WebFetch of `pub.dev/packages/flutter_local_notifications` — current version/exact-alarm
  setup summary (cross-checked against the registry API above)
- WebSearch: `flutter_timezone` vs `iana_time_zone` comparison (single search, not
  independently re-verified beyond pub.dev metrics)

### Tertiary (LOW confidence)
- None retained — all findings were cross-verified against the pub.dev registry or the openGym
  source directly.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every version verified live against the pub.dev registry API on
  research date; package identities came from well-known training knowledge, hence still tagged
  `[ASSUMED]` per the provenance rule pending `checkpoint:human-verify`.
- Architecture: HIGH — directly grounded in existing, already-committed Flutter code (`D-02`
  markers, existing `GymState` fields) plus openGym's own source, not guesswork.
- Pitfalls: HIGH — Android exact-alarm and iOS silent-switch issues are both explicitly
  documented by the plugin's own docs and by openGym's own source comments (issue #152), not
  speculative.

**Research date:** 2026-09-30
**Valid until:** 30 days (stable domain, but Android exact-alarm policy and plugin major versions
move fast enough to warrant re-checking versions if planning is delayed)
