# 05-05 Summary: WorkoutTimerBloc, RestTimerBar, TimerFlash, WorkoutTimerHost

**Status:** Complete  
**Date:** 2026-09-30  
**Phase:** 05-timers-guest-mode  
**Plan:** 05-05

## What was built

### Task 1 — WorkoutTimerBloc + provider

| File | Purpose |
|------|---------|
| `lib/features/workout/bloc/workout_timer_event.dart` | 12 sealed event subclasses (sealed `WorkoutTimerEvent`) |
| `lib/features/workout/bloc/workout_timer_state.dart` | Sealed state: `WorkoutTimerIdle`, `WorkoutRestRunning`, `WorkoutWorkRunning` + signals |
| `lib/features/workout/bloc/workout_timer_bloc.dart` | Port of useUI.js timer/work slice; single `on<>` with `_sequential` |
| `lib/app/providers/timer_providers.dart` | `timerBlocProviders(deps)` returning lazy:false `BlocProvider<WorkoutTimerBloc>` |

**Semantics verified:**
- `startRest` / `addRest` / `shiftRestOwner` / `stopRest` match useUI.js lines 107-165
- `startWork` / `finishWorkEarly` / `stopWork` match useUI.js lines 167-198
- `seenLive` rule: first tick after return is NOT live (hiddenAt cleared after tick)
- Tone frequencies: 880 Hz × 2, 1320 Hz, 660 Hz last-3-ticks ✓
- Vibration patterns: `[200, 100, 200]` (complete), `30` (finishEarly) ✓
- `cancelRestOver` called ≥ 3 sites (stopRest, AppShown, close) ✓
- `scheduleRestOver` called only in AppHidden path ✓
- No `dart:math`; js04_audit PASS ✓

### Task 2 — UI widgets + shell/app wiring

| File | Purpose |
|------|---------|
| `lib/features/workout/view/widgets/rest_timer_bar.dart` | Port of RestTimer.jsx: idle hides, rest shows m:ss + bar + -15s/+15s/Skip, work shows row with accent border + clock + label + bar + Cancel/Done |
| `lib/features/workout/view/widgets/timer_flash.dart` | Port of TimerFlash.jsx: fires [opposite, original, opposite, original] at 0/600/1200/1800 ms on flashId change |
| `lib/features/workout/view/widgets/workout_timer_host.dart` | `AppLifecycleListener` forwards hide/show to `WorkoutTimerBloc`; `BlocListener` shows rest-over toast |
| `lib/features/shell/view/shell_page.dart` | Body wrapped in `WorkoutTimerHost`; `RestTimerBar` + `AppTabBar` in `Column` bottomNavigationBar |
| `lib/app/app.dart` | `timerBlocProviders` added before `workoutBlocProviders`; `BlocSelector<WorkoutTimerBloc, _, int>(flashId)` wraps `TimerFlash(…)` wraps `MaterialApp.router` in both `ShellInitial` and `ShellReady` branches |

## Verification results

```
flutter analyze        → No issues found!
bash tool/js04_audit.sh → JS-04 audit: PASS
bash tool/guest_audit.sh → GUEST AUDIT: PASS
grep -c cancelRestOver → 4
grep -n scheduleRestOver → in _onAppHidden only
grep -c "on<" bloc → 1
grep -c "^final class" event → 12
grep -n "timerBlocProviders" app.dart → line 117, before workoutBlocProviders (line 119)
grep -c "createAppRouter" app.dart → 3 (unchanged)
```

## Requirements satisfied

- **TMR-01** (countdown + sound + flash + vibration): Bloc fires correct tone sequences and `_flash()` on rest/work completion; `TimerFlash` flips theme.
- **TMR-02** (background rest notification): `scheduleRestOver` on hide, `cancelRestOver` on show, skip, and close.
- **D-07**: Numbers, sounds and flash follow openGym exactly.
- **D-09**: Work/hold timer wired alongside rest timer in same widget.

## What's next

- **05-07**: Connect `WorkoutBloc` call sites to `WorkoutTimerBloc` (trigger startRest after set toggle, etc.)
- **05-08**: Device UAT once 05-07 is wired.
