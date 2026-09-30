# Phase 5: Timers & Guest Mode - Context

**Gathered:** 2026-09-30
**Status:** Ready for planning
**Source:** User direction in `/gsd-plan-phase` arguments (2026-09-30), plus follow-up answers

<domain>
## Phase Boundary

Phase 5 delivers:
- The in-app rest timer with sound, flash and wakelock, matching openGym settings (TMR-01)
- An exact local notification when rest ends while the app is backgrounded; returning or skipping cancels it (TMR-02)
- A daily workout reminder (time + timezone) as a local notification (TMR-03)
- Guest-only operation: the app runs fully with no account and no server (AUTH-05)

Phase 5 does NOT deliver: server URL setup, passkey sign-in, pairing codes, logout, or any online sync.
Those parts (AUTH-01..04, SYNC-01..03) were removed from v1 by the user on 2026-09-30.

</domain>

<decisions>
## Implementation Decisions

### Guest mode (locked)
- Guest mode is the ONLY mode. There is no sign-in screen, no server URL field, no account section,
  and no logout. Where openGym shows server/account/sync UI (Login, SyncBanner, Settings account
  rows, server-only buttons), the port hides it or replaces it with a local equivalent.
- No user data leaves the device. No network calls for user data (no `/api/data`, `/api/push/*`, etc.).
- Guest behaviour follows openGym's `lib/guest.js` wherever that logic applies to a no-server app.
- `flutter_passkey_service` is no longer used in v1. Do not add it in this phase.

### Timers & notifications (locked)
- Keep TMR-01..03 in this phase, as on the original roadmap.
- Use `flutter_local_notifications` (user-mandated) for the rest-end and daily reminder
  notifications. openGym's web push (`push.js`, `/api/push/rest-timer`) becomes local notifications.
- Timer numbers, sound choice and flash follow openGym (`RestTimer.jsx`, `TimerFlash.jsx`, `sound.js`).

### Phase 6 hand-off (for awareness, not planned here)
- Phase 6 becomes Local Backup & Restore: periodic full-state JSON backups to a user-chosen device
  folder, a manual backup in Settings, and a full restore from a backup file (the backup is the
  master copy, like signing in again after a logout). Phase 5 must not build anything that
  assumes a server, so Phase 6 can add its Settings section cleanly.

### Claude's Discretion
- Exact-alarm permission handling on Android 12+/14 (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) and
  iOS notification permission prompts, with a graceful fallback when permission is denied.
- The wakelock mechanism and where timer state lives (Bloc layout per project conventions).
- How server-only openGym UI is hidden (removed routes vs hidden rows), as long as no dead
  server UI is reachable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### openGym source (read-only reference)
- `../openGym/frontend/src/components/RestTimer.jsx` — rest timer UI and behaviour
- `../openGym/frontend/src/components/TimerFlash.jsx` — end-of-rest flash
- `../openGym/frontend/src/lib/sound.js` — timer sounds
- `../openGym/frontend/src/lib/push.js` — rest-timer push + reminder scheduling (becomes local notifications)
- `../openGym/frontend/src/lib/mobile.js` — Capacitor/mobile behaviour (notifications, wakelock)
- `../openGym/frontend/src/lib/guest.js` — guest-mode logic
- `../openGym/frontend/src/views/Workout.jsx` — where the rest timer is triggered
- `../openGym/frontend/src/views/Settings.jsx` — timer, sound and reminder settings
- `../openGym/frontend/src/views/Login.jsx`, `../openGym/frontend/src/components/SyncBanner.jsx`,
  `../openGym/frontend/src/App.jsx` — server/account UI that guest-only mode must not expose

### Project
- `CLAUDE.md` — stack, conventions, no-tests rule
- `.claude/skills/port-from-opengym/SKILL.md` — porting workflow
- `.planning/REQUIREMENTS.md` — TMR-01..03, AUTH-05, and the Out of Scope entry for accounts/sync

</canonical_refs>

<specifics>
## Specific Ideas

- The user's goal: "no data will ever be online, keeping user information safe."

</specifics>

<deferred>
## Deferred Ideas

- Local backup & restore (Phase 6).
- Phase 7 (Coach & Admin) depends on a server in openGym; its scope needs a decision before Phase 7 planning.

</deferred>

---

*Phase: 05-timers-guest-mode*
*Context gathered: 2026-09-30 from user direction*
