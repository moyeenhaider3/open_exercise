# Phase 3: BLoC & UI Translation - Research

**Researched:** 2026-09-28
**Domain:** Flutter/Material 3 UI + flutter_bloc state management, translating a React/Zustand SPA (openGym) 1:1
**Confidence:** MEDIUM-HIGH (screen inventory and JS bridge inventory are HIGH confidence — read directly from source; several architecture/scope decisions below are recommendations requiring user confirmation, marked `[ASSUMED]`)

## Summary

Phase 3 ports six openGym screens (Library, Workout, Plan/RoutineEdit, History/Stats, Home/CheckIn, Settings)
plus ~40 "sheets" (bottom-sheet forms) to Material 3, wired through flutter_bloc, on top of the
Phase 1 `GymStateRepository`/sqflite layer and the Phase 2 QuickJS bridge (`OnermJs`, `BarJs`,
`WorkoutModelJs`, `ProgressionJs`, `RecoveryJs`, `HistoryJs`, `SessionStartJs`, `SessionMergeJs`).
Workout.jsx (1140 lines) is the dominant complexity driver: straight/warm-up/drop-set/rest-pause/
per-side/superset/cardio/timed set logging, all delegating math to the bridge and needing only
Dart-side flow-control (which JS does NOT bridge — see "Don't Hand-Roll" and "Code Examples" below).

Three findings materially change the phase's shape versus its description and must be confirmed
with the user before/while planning:

1. **Exercise media is not a bundled Flutter asset.** openGym's own mobile (Capacitor) build points
   `VITE_IMG_BASE`/`VITE_GIF_BASE` at a public jsDelivr CDN mirror of a third-party dataset (~140 MB,
   © Gym Visual, non-AGPL, not redistributed by openGym). The Flutter port should do the same —
   fetch over HTTP from the same pinned CDN commit, with Flutter's built-in in-memory `ImageCache`
   (via `Image.network`) satisfying UI-02's "cached in memory" requirement — not ship 140 MB as assets.
2. **The Stats screen spans two phases.** Its "Muscle balance / Fatigue / Strength" card renders
   through `BodyMap` (SVG muscle silhouette), which is explicitly Phase 4 (MAP-01..03) work. Phase 3
   must ship Stats without that card (bodyweight chart, exercise-progress chart, effort card,
   activity heatmap, recent-workouts list only) and add the muscle-map card as a Phase 4 addition.
3. **openGym's custom sheet-stack (`Modals.jsx`/`useUI.openSheet`) should NOT be ported 1:1.** It
   reimplements swipe-to-dismiss, Android-back-dismisses-top-sheet, and body-scroll-locking by hand
   because the web has no native equivalent. Flutter's `showModalBottomSheet`/`showDialog` already
   provide all of this (drag-to-dismiss, route-stack-based back dismissal, focus scrim) for free.
   Porting the JS gesture code would be substantial wasted effort and a source of subtle diffs from
   platform-native sheet behaviour.

**Primary recommendation:** Build one root `GymStateCubit` (the single writer to
`GymStateRepository`, mirroring `useStore`'s `S` + `update(mut)`) that every feature Bloc
(`WorkoutBloc`, `PlanBloc`, `LibraryBloc`/`LibraryCubit`, `HistoryBloc`/`StatsCubit`,
`SettingsCubit`, `CheckInCubit`) reads and writes through — never sqflite directly — to avoid
write races between concurrent feature Blocs on the single flat `GymState` document. Use native
Flutter modals/`ReorderableListView`/`CustomPainter` instead of porting openGym's hand-rolled
sheet-stack, drag-reorder and chart code. Split this phase into two sub-phases at plan time (see
"Scope: Recommended Phase Split" below) — it is too large for one linear plan sequence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Exercise search/filter/favourite (UI-01) | Bloc (`LibraryBloc`) | Widget (search field, chips) | Pure Dart port of `exercises.js` search algorithm; no I/O |
| Exercise detail + media (UI-02) | Widget (`Image.network` + Flutter `ImageCache`) | Bloc (favourite toggle only) | Media is a remote fetch, not app state |
| Active workout session (UI-03) | Bloc (`WorkoutBloc`) | JS Bridge (`WorkoutModelJs`, `ProgressionJs`, `HistoryJs`, `SessionStartJs`) | All set-type/phase/progression math is bridged; Bloc owns flow only |
| Routines / weekly plan (UI-04) | Bloc (`PlanBloc`) | Widget (`ReorderableListView`) | CRUD + ordering over `GymState.routines`/`week` |
| History & Stats charts (UI-05) | Bloc (`StatsCubit`/`HistoryBloc`) | JS Bridge (`OnermJs`, `HistoryJs`), Widget (`CustomPainter` charts) | Chart math (axis scaling) is presentation, not domain math — stays in Dart |
| Settings (UI-06) | Bloc (`SettingsCubit`) | Repository (`GymStateRepository`) | Simple field read/write, no bridge calls |
| Sheet/dialog presentation (part of UI-07) | Widget (Navigator: `showModalBottomSheet`/`showDialog`) | — | Flutter's route stack replaces `useUI`'s custom stack entirely |
| Toast messages (part of UI-07) | Widget (`SnackBar`) or a 3-line `ToastCubit` | — | No sheet-stack coupling needed |
| Persistence of all of the above | Repository (`GymStateRepository`, Phase 1) | Bloc (single writer: `GymStateCubit`) | Existing sqflite schema already supports `active`/`routines`/`workouts`/settings round-trip |
| 1RM / progression / plate / recovery / history math | JS Bridge (QuickJS, Phase 2) | — | JS-04: never hand-derive in Dart |
| Muscle map / fatigue shading (Stats sub-card) | **Phase 4** (out of scope here) | — | Depends on `body-paths.js` + `CustomPainter`, not yet built |
| Rest/work timers, background alerts (TMR-01..03) | **Phase 5** (out of scope here) | — | Explicitly owned by Phase 5 per ROADMAP.md |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Browse, typo-tolerant search, filter by muscle/equipment, favourite exercises | `lib/exercises.js` search algorithm fully documented below (Code Examples); `Library.jsx` screen map; `favourites.js`/`equipment.js` are trivial Dart ports |
| UI-02 | Exercise detail + animated WebP/GIF, cached in memory | CDN media strategy (Summary #1); `Media.jsx`/`Thumb` component map; Flutter `Image.network` + built-in `ImageCache` |
| UI-03 | Start/run/finish workout: straight/warm-up/drop/rest-pause sets, steppers, progression, reorder, swap, supersets | `Workout.jsx` fully read and documented (Architecture Patterns, Code Examples); bridge coverage confirmed 100% for `workoutModel`/`progression`/`history`/`session*`; flow-control modules (`supersetFlow.js`, `active-workout-order.js`, `active-exercise-swap.js`) documented for direct Dart port |
| UI-04 | Create/edit routines and weekly plan, drag to reorder | `Plan.jsx`/`RoutineEdit.jsx` fully read; drag gesture in RoutineEdit is a hand-rolled pointer/long-press system — recommend `ReorderableListView` instead (Don't Hand-Roll) |
| UI-05 | History and Stats: charts, heatmap, 1RM trends, bodyweight | `Stats.jsx`/`Heatmap.jsx`/`LineChart.jsx` fully read; muscle-map sub-card scoped OUT to Phase 4 (Summary #2) |
| UI-06 | Home, Check-in, Settings with same options | `Home.jsx`/`CheckIn.jsx`/`Settings.jsx` read; Settings section-by-section split across Phase 3/5/6/7/8 documented below; CheckIn's card-adding flow needs barcode scan (IMP-03, Phase 8) — Phase 3 ships list/QR-display/reorder/delete only |
| UI-07 | Every Zustand action has a Bloc event | Full `useStore.js`/`useUI.js` action inventory below, each tagged with owning phase or "replaced by Flutter Navigator/native widget" |
| UI-08 | `ListView.builder`/slivers everywhere; layouts match 1:1 | Every list in the screens read uses unbounded `.map()` in React; Flutter equivalents specified per screen below |
</phase_requirements>

## Standard Stack

### Core (already installed, Phase 1/2)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | ^9.1.1 | State management | Project-mandated |
| equatable | ^3.0.0 | Value equality for states/events | Project-mandated |
| sqflite | ^2.4.4 | Persistence (via `GymStateRepository`) | Project-mandated, already schema'd |
| go_router | ^18.0.1 | Routing | Already wired in `lib/core/router/app_router.dart` |
| dio / retrofit | ^5.11.1 / ^4.10.0 | HTTP (media fetch reuses this or plain `Image.network`) | Already generated from openapi.yaml |

### Supporting (newly invoked this phase, already mandated project-wide but not yet added to pubspec.yaml)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| path_drawing | 1.0.1 [VERIFIED: pub.dev] | Parse the 82 hand-drawn SVG "d" path strings from openGym's `Icon.jsx` into Flutter `Path` objects via `parseSvgPathData()`, rendered with `CustomPaint` | Icon rendering only in Phase 3; Phase 4 also needs it for `body-paths.js` — installing it now means Phase 4 does not re-litigate the dependency |

**No other new pub packages are required for Phase 3.** Charts (`LineChart.jsx`, `Heatmap.jsx`) are
hand-rolled SVG in openGym with no third-party chart library — port them as `CustomPainter`
widgets. Number/date formatting (`fmtNum`, `fmtDate`, `DAYN`, `MONTHS`) reads from small hardcoded
English arrays in openGym today (there is no `locales/en.js` — English strings ARE the `t()` call
literals) and does not need `package:intl`; hand-roll the same small English-only formatters in
Dart and defer locale-aware formatting to Phase 8 (I18N-01/02). Drag-to-reorder does not need a
new package (`ReorderableListView`/`SliverReorderableList` are Flutter SDK).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `path_drawing` for icons | Custom icon font (IcoMoon/FlutterIcon export) | Extra build tooling, harder to keep in sync with openGym's `Icon.jsx` additions; `path_drawing` reuses raw path data directly, 1:1 traceable |
| `path_drawing` for icons | `flutter_svg` | Not mandated; would need real `.svg` files (openGym's icons are inline JSX path strings, not files) — `path_drawing`'s `parseSvgPathData` works directly on the `d` string without a full SVG document |
| Hand-rolled `CustomPainter` charts | `fl_chart` / `syncfusion_flutter_charts` | Both are unmandated new dependencies; openGym's own charts are simple (line + gradient fill + gridlines, GitHub-style heatmap) — well within `CustomPainter` scope, matches project's minimal-dependency stance |
| Hand-ported typo-tolerant search | A fuzzy-search pub package (e.g. `fuzzywuzzy` style) | Would not reproduce openGym's exact scoring/edge cases (`search-typo.test.js`); parity requires porting the literal algorithm |
| `showModalBottomSheet`/`showDialog` | Custom sheet-stack (port `Modals.jsx`) | Reinvents swipe-to-dismiss, Android back-dismiss, focus scrim that Flutter's Navigator already provides |

**Installation:**
```bash
flutter pub add path_drawing
```

**Version verification:** `path_drawing` 1.0.1, published 2022-08-04, by `dnfield` (also the author
of `flutter_svg`; this is `flutter_svg`'s own path-parsing dependency, split out as a standalone
package) [VERIFIED: pub.dev API, `https://pub.dev/api/packages/path_drawing`]. `xml` 7.1.0 (already
mandated for Phase 4, not needed by Phase 3 since openGym's icons are inline path strings, not full
SVG documents) [VERIFIED: pub.dev API].

## Package Legitimacy Audit

> Only one new package is added this phase. `slopcheck` (per the standard protocol) targets
> npm/PyPI; it has no pub.dev integration, so registry verification was done directly against the
> pub.dev API instead of via slopcheck.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| path_drawing | pub.dev | ~4 years (published 2022-08-04, latest 1.0.1) | Not exposed by the pub.dev API used; widely depended-upon as `flutter_svg`'s own path-parser | `github.com/dnfield/flutter_path_drawing` | N/A (pub.dev, not npm/PyPI) | Approved — pre-authorized in CLAUDE.md's mandated stack; registry existence and maintainer identity confirmed directly via pub.dev API |

**Packages removed due to slopcheck [SLOP] verdict:** none (slopcheck not applicable to this ecosystem)
**Packages flagged as suspicious [SUS]:** none

*`path_drawing` was already a locked project decision (CLAUDE.md "Stack (user-mandated)") before
this research; the check above is a registry-existence/maintainer sanity check for the version
being installed, not a re-litigation of the choice itself.*

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Widgets (Library/Workout/Plan/RoutineEdit/History/Stats/Home/           │
│  CheckIn/Settings screens; ~40 sheet widgets via showModalBottomSheet)   │
└───────────────┬───────────────────────────────────────────┬─────────────┘
                │ dispatch events                            │ Image.network
                ▼                                             ▼
┌───────────────────────────────┐                    ┌─────────────────────┐
│ Feature Blocs                  │                    │ Pinned CDN          │
│  LibraryBloc  WorkoutBloc      │                    │ (jsDelivr mirror of │
│  PlanBloc     StatsCubit       │                    │ exercises-dataset)  │
│  SettingsCubit CheckInCubit    │                    │ img/*.jpg gif/*.gif │
└───────┬────────────────┬───────┘                    └─────────────────────┘
        │ read/mutate     │ pure math calls
        ▼                 ▼
┌─────────────────┐   ┌───────────────────────────────────────┐
│ GymStateCubit    │   │ JsEngineService facades (Phase 2)      │
│ (single writer,  │   │ OnermJs BarJs WorkoutModelJs           │
│ owns in-memory   │   │ ProgressionJs RecoveryJs HistoryJs     │
│ GymState = S)    │   │ SessionStartJs SessionMergeJs          │
└───────┬──────────┘   └───────────────────────────────────────┘
        │ importState/exportState/loadState/saveState
        ▼
┌─────────────────────────┐
│ GymStateRepository        │
│ over AppDatabase (sqflite)│
└─────────────────────────┘
```

A user tap flows: Widget → Bloc event → (Bloc calls a JS-bridge facade for any math) → Bloc calls
`GymStateCubit.mutate(...)` → `GymStateCubit` clones, applies the mutation, persists via
`GymStateRepository.saveState`, and emits the new `GymState` → every Bloc/widget listening to the
relevant slice rebuilds.

### Recommended Project Structure
```
lib/features/
├── library/          # UI-01, UI-02: bloc/ data/ (search port) view/
├── workout/           # UI-03: bloc/ (WorkoutBloc, largest) view/ (ExerciseBlock, SetRow widgets)
├── plan/              # UI-04: bloc/ (PlanBloc) view/ (Plan, RoutineEdit)
├── history_stats/     # UI-05: bloc/ (StatsCubit) view/ (charts as CustomPainter)
├── home/              # UI-06 (Home): bloc/ (HomeCubit) view/
├── checkin/           # UI-06 (Check-in, display-only this phase): bloc/ view/
├── settings/          # UI-06 (Settings, non-auth/sync/coach rows): bloc/ view/
└── shell/             # existing (Phase 1) — extend GymStateCubit here or lib/core/state/
lib/core/
├── state/             # NEW: GymStateCubit (single writer), shared across features
├── ui_kit/            # NEW: AppIcon (path_drawing CustomPainter), LineChartPainter,
│                       #      HeatmapPainter, sheet helpers (showAppSheet), formatting
│                       #      (fmtNum/fmtDate/DAYN/MONTHS Dart ports)
└── js/ db/ data/ models/ theme/ router/  # existing (Phase 1/2)
```

### Pattern 1: Single-writer GymStateCubit, feature Blocs as readers/dispatchers
**What:** One `GymStateCubit extends Cubit<GymState>` owns the canonical in-memory state and is
the only class that calls `GymStateRepository.saveState`. It exposes a generic
`Future<void> mutate(GymState Function(GymState) fn)` (mirrors `update(mut)` in `useStore.js`)
plus a handful of named convenience methods. Feature Blocs (`WorkoutBloc`, `PlanBloc`, etc.) take
a `GymStateCubit` via constructor injection, read its `state` for the slice they need, and call
`.mutate()` to write. They do NOT hold their own persisted copy of `GymState`.
**When to use:** Every feature Bloc in this phase, and — as a follow-up refactor this phase should
flag but not necessarily execute — Phase 1's existing `ShellBloc` should eventually delegate to
the same cubit rather than loading its own copy, to keep exactly one writer.
**Example:**
```dart
// lib/core/state/gym_state_cubit.dart
class GymStateCubit extends Cubit<GymState> {
  GymStateCubit(this._repo, this._uid) : super(GymState.defaults()) {
    _load();
  }
  final GymStateRepository _repo;
  final String _uid;

  Future<void> _load() async {
    final loaded = await _repo.loadState(_uid);
    emit(loaded ?? GymState.defaults());
  }

  /// Mirrors useStore.js's `update(mut, push)`: clone, mutate, persist, emit.
  Future<void> mutate(GymState Function(GymState draft) fn) async {
    final next = fn(state); // GymState is immutable; fn returns a new value via copyWith
    await _repo.saveState(_uid, next);
    emit(next);
  }
}
```

### Pattern 2: WorkoutBloc flow-control ported directly from small pure JS modules (not bridged, not domain math)
**What:** `lib/supersetFlow.js` (`nextUnfinishedUnit`, `insertionIndexAfterCurrentUnit`,
`setProgressHighWater`, `restAfterSet`/`restOnRecheck`, `restSecFor`, `warmupRestSecFor`,
`supersetFlowStep`), `lib/active-workout-order.js` (`canMoveActiveWorkoutUnit`,
`moveActiveWorkoutUnit`) and `lib/active-exercise-swap.js` (`swapActiveExercise`) are pure
array/index logic over `entries`/`units` — no 1RM/progression/plate math, so JS-04 does not
require bridging them (Phase 2's bridge inventory does not include them; confirmed by reading
`tool/js/bridge-inventory.mjs`'s scope in the Phase 2 summaries). Port them verbatim into
`WorkoutBloc`-private helper functions, each with a comment citing the exact openGym source file
and function name, the same traceability convention Phase 1 used before JS-04 cleanup (CR-02)
removed hand-ported *math*. This is flow control, not math, so it is not a JS-04 violation.
**When to use:** `WorkoutBloc`'s reorder/swap/supersedet-navigation event handlers.
**Example:**
```dart
// Ported from ../openGym/frontend/src/lib/supersetFlow.js:restSecFor (flow-control, not domain
// math — JS-04 does not require bridging this; see 03-RESEARCH.md Pattern 2).
int restSecFor(List<WorkoutEntry> entries, List<int> unit, int defaultRestSec) {
  final fallback = defaultRestSec > 0 ? defaultRestSec : 0;
  if (unit.isEmpty) return fallback;
  var longest = 0;
  for (final idx in unit) {
    final own = entries[idx].target?.restSec ?? 0;
    final candidate = own > 0 ? own : fallback;
    if (candidate > longest) longest = candidate;
  }
  return longest;
}
```

### Pattern 3: Native modal routing instead of a sheet-stack Bloc
**What:** A thin helper `Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder, {bool locked = false})`
wraps `showModalBottomSheet<T>(context: context, isDismissible: !locked, enableDrag: !locked,
useSafeArea: true, builder: builder)`. Centered dialogs (`workoutCompleteSheet`'s `kind: 'center'`)
use `showDialog` instead. No `SheetBloc`/`sheets` list is needed — Flutter's `Navigator` route
stack already handles stacking, Android back-dismisses-top-sheet, and swipe-to-dismiss.
**When to use:** Every one of the ~40 `xSheet()` functions in `sheets.jsx`.
**Example:**
```dart
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder, {bool locked = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: !locked,
    enableDrag: !locked,
    builder: builder,
  );
}
```

### Anti-Patterns to Avoid
- **Porting `Modals.jsx`'s manual history-entry-pushing/pointer-drag code:** Flutter's Navigator
  already owns back-button semantics and gesture-driven dismissal; hand-porting the JS defeats the
  platform-native behaviour users expect.
- **A Bloc per sheet:** ~40 sheets do not each need a Bloc. Most are simple forms that call back
  into an existing feature Bloc's event (e.g. `exConfigSheet`'s `onSave` callback → dispatch a
  `WorkoutEntryConfigured` event). Give a sheet a `StatefulWidget`'s local `setState` for its own
  draft fields, and only dispatch to a Bloc on confirm.
- **Multiple Blocs each calling `GymStateRepository.saveState` independently:** creates the exact
  read-stale/write-stale race `useStore.js` avoids by funnelling everything through one `update()`.
  Route all persistence through `GymStateCubit`.
- **Hand-rolling 1RM/progression/plate/recovery/history math "just for this screen" (e.g. computing
  a chart's best-1RM point manually instead of calling `OnermJs.e1rmSeries`):** violates JS-04 even
  when the call site is a chart, not the workout screen.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bottom sheet / dialog stacking, swipe-to-dismiss, back-button dismissal | A custom `SheetBloc` + gesture detector porting `Modals.jsx` | `showModalBottomSheet` / `showDialog` (Flutter SDK) | Platform-native behaviour already covers every case `Modals.jsx` hand-rolls for the web |
| Drag-to-reorder (routine exercises, weekly plan) | Custom long-press + pointer-move + auto-scroll (`RoutineEdit.jsx`'s `useRoutineReorder`, ~230 lines) | `ReorderableListView` / `SliverReorderableList` (Flutter SDK) | Native long-press-drag-reorder with auto-scroll built in |
| Icon rendering (82 hand-drawn icons) | New icon font pipeline, or hand-writing 82 `CustomPainter`s from scratch | `path_drawing`'s `parseSvgPathData()` on the same `d` strings from `Icon.jsx`, one shared `AppIcon` `CustomPainter` | Direct 1:1 reuse of the exact path data, matches "port pixel geometry" more literally than redrawing by hand |
| Line/bar/heatmap charts | A chart package (`fl_chart`, etc.) | `CustomPainter` (mirrors openGym's own hand-rolled SVG) | No new dependency; openGym's charts are simple enough that a package is unjustified |
| Typo-tolerant exercise search | A generic fuzzy-search package | Verbatim Dart port of `exercises.js`'s `searchScore`/`matchExercise`/`searchExercises`/`nearWord`/`normalizeStr` (documented below) | Parity with `search-typo.test.js`'s exact edge cases requires the exact algorithm, not "similar" fuzzy matching |
| 1RM, progression, plate math, recovery/fatigue decay, set-phase/type resolution, session building/merging | Any Dart re-derivation, even for "just a chart" or "just a label" | `OnermJs`/`ProgressionJs`/`BarJs`/`RecoveryJs`/`WorkoutModelJs`/`HistoryJs`/`SessionStartJs`/`SessionMergeJs` (Phase 2, already built) | JS-04 (project rule), enforced by `tool/js04_audit.sh` |
| Locale-aware number/date formatting | `package:intl` | Hand-rolled `fmtNum`/`fmtDate` matching the exact English-only algorithm in `format.js` (below) | i18n is Phase 8; adding `intl` now is unmandated and premature — English literal strings are the actual "source of truth" in openGym today (there is no `locales/en.js`) |

**Key insight:** openGym's own JS already separates "domain math" (bridged, Phase 2) from "flow
control / presentation" (small pure functions with no bridge entry). The temptation in Phase 3 is
to either (a) accidentally re-derive domain math while writing "just a label," or (b) over-port
web-specific plumbing (custom sheet stack, custom drag gestures) that Flutter's SDK already solves
better natively. Both mistakes are avoidable by checking the Phase 2 bridge inventory before
writing any calculation, and checking Flutter's SDK widget catalog before porting any gesture code.

## Zustand Action Inventory (UI-07 checklist)

Every action in `../openGym/frontend/src/store/useStore.js` and `useUI.js`, with its owning phase.
Actions marked **Phase 3** need a Bloc event (or, where noted, a native Flutter API call, which
satisfies UI-07's intent — "an equivalent" — without a Bloc event, per Pattern 3 above).

### `useStore.js`

| Zustand action | What it touches | Phase | Flutter equivalent |
|---|---|---|---|
| `update(mut, push)` | Generic state mutator — the action nearly every screen actually calls | **Phase 3** | `GymStateCubit.mutate(fn)` |
| `replaceState(S, push)` | Whole-state replace (backup import, reset) | **Phase 3** (Settings "Reset everything"; full Hevy/CSV import is Phase 8) | `GymStateCubit.replace(GymState)` |
| `autoBackupNow()` | Mobile file-mirror backup after a meaningful change | Phase 8 (IMP-04) | — (no-op this phase) |
| `isGuest()` / `setGuest(v)` | Guest-mode flag | Phase 5 (AUTH-05) | — |
| `loadConfig()` / `refreshConfig()` | `/api/config` fetch | Phase 5/6 | — |
| `setUser(u)` | Signed-in user | Phase 5 | — |
| `pushState()` / `pullState()` | Server sync | Phase 6 (SYNC-01) | — |
| `adoptProfile(ask)` | Sign-in profile merge | Phase 6 | — |
| `signOut()` / `signOutAll()` | Sign-out (+ all devices) | Phase 5 (AUTH-04) | — |
| `chooseLocalMode()` | Mobile onboarding "stay local" | Phase 5 | — |
| `connectToServer(url, code, ask)` | Pairing-code sign-in | Phase 5 (AUTH-03) | — |
| `disconnectServer()` | Leave remote mode | Phase 5 | — |
| `resetDemo()` | Web-demo-build only | N/A (no demo build in Flutter) | — |
| `boot()` | App-start orchestration (server ping, pull, guest fallback) | Phase 1 already ships a reduced version (`ShellBloc._loadOrDefaults`); full server/guest branching is Phase 5/6 | Extend `ShellBloc`/`GymStateCubit` init in Phase 5, not Phase 3 |
| `setCoachLocal(patch)` | AI Coach device settings | Phase 7 | — |

### `useUI.js`

| Zustand action | What it touches | Phase | Flutter equivalent |
|---|---|---|---|
| `openSheet(render, opts)` / `closeSheet(id)` / `closeAll()` | Sheet stack | **Phase 3** | `showAppSheet()` / `Navigator.pop()` / `Navigator.popUntil()` (Pattern 3 — no Bloc needed) |
| `toast(msg)` | Toast banner | **Phase 3** | `ScaffoldMessenger.showSnackBar` or a 3-line `ToastCubit` if a persistent on-screen banner (not auto-dismissing `SnackBar`) is wanted to match openGym's fixed 2200ms toast exactly |
| `flashTimer()` | Screen-flash visual alert on rest/work timer end | Phase 5 (TMR) | — |
| `startRest(sec, forIdx)` / `addRest(sec)` / `shiftRestOwner(at, delta)` / `stopRest()` | Rest countdown between sets | Phase 5 (TMR-01) | — (see Open Questions — Phase 3 workout flow ships without a live rest countdown) |
| `startWork(sec, label, onDone)` / `finishWorkEarly()` / `stopWork()` | Timed-set hold countdown | Phase 5 (TMR-01, shares infra with rest timer) | Phase 3 supports timed-mode sets by typing seconds directly (`NumberField`-equivalent), no live countdown |

**If this inventory looks incomplete for "every Zustand action":** it is complete for both files.
Screen-specific mutations (adding a set, editing a routine, toggling a switch) are NOT separate
Zustand actions in openGym — they are all inline closures passed to the single `update(mut)`
action from within `views/*.jsx` and `sheets.jsx`. Phase 3's `WorkoutBloc`/`PlanBloc`/etc. events
are the Dart equivalent of those closures, not of additional store actions — there are none to
enumerate beyond `update()` itself. This is why `GymStateCubit.mutate()` (mirroring `update`) is
the single load-bearing primitive in the Architecture Patterns above.

## Screen-by-Screen Map

| openGym source | Flutter screen/widget | M3 pattern | Notes / phase split |
|---|---|---|---|
| `views/Library.jsx` (80 lines) | `LibraryScreen` (`lib/features/library/view/`) | `Scaffold` + sticky header row + horizontal `ListView` chip strips (body part, equipment) + `ListView.builder` results | Search field, "Create your own exercise" row, per-row favourite star + "Plan" button. UI-08: results list MUST be `ListView.builder`, not `Column`+`map` |
| `views/Muscles.jsx` (15 lines) + `components/MuscleExplorer.jsx` | **Phase 4** | — | Delegates entirely to `BodyMap`; out of scope |
| `sheets.jsx: exerciseDetailSheet` | `ExerciseDetailSheet` (bottom sheet) | `Media`-equivalent (network image/gif, tap-to-pause) + instructions list + favourite toggle | UI-02 |
| `views/Workout.jsx` (1140 lines) — `StartChooser` | `WorkoutStartScreen` | Today's-plan card + other-routines `ListView.builder` + freestyle button | Shown when `GymState.active == null` |
| `views/Workout.jsx` — `ActiveWorkout`/`ExerciseBlock` | `ActiveWorkoutScreen` + `ExerciseBlockWidget` + `SetRowWidget` | Cards / List / Compact layout modes (Settings-driven), superset grouping, per-side L/R sub-rows, drop/burst sub-rows | The single most complex screen — see Architecture Patterns / Code Examples. UI-08: List/Compact modes MUST use `ListView.builder`; Cards mode is a single-unit view with Prev/Next, no list needed there |
| `views/Plan.jsx` (115 lines) | `PlanScreen` | Week-schedule list (7 fixed rows, `Column` is fine — bounded to 7) + Routines `ReorderableListView` | UI-04. "Load starter plan" empty state |
| `views/RoutineEdit.jsx` (465 lines) | `RoutineEditScreen` | `ReorderableListView` (replaces the 230-line hand-rolled drag system) + swipe-to-delete (`Dismissible` replaces `SwipeToDelete.jsx`) + `BodyMap` "what this session hits" card (**Phase 4**, omit for now) | UI-04. Superset linking via a "link" icon button per row |
| `views/History.jsx` (18 lines) | `HistoryScreen` | `ListView.builder` of `WorkoutRow` | UI-05 |
| `views/Stats.jsx` (513 lines) — bodyweight/exercise-progress/effort/heatmap/recent-workouts | `StatsScreen` | `CustomPainter` line charts (bodyweight, exercise progress, effort trend), `CustomPainter` GitHub-style heatmap, `ListView.builder` recent workouts | UI-05. Ship this subset only |
| `views/Stats.jsx` — `MuscleBalance` (BodyMap-based) | **Phase 4** | — | Explicitly deferred (Summary #2) |
| `views/Home.jsx` (187 lines) | `HomeScreen` | Week strip (7 fixed cells), today card, bodyweight card + chart, streak card | UI-06 |
| `views/CheckIn.jsx` (253 lines) | `CheckInScreen` | Horizontal `PageView`/scroll rail of QR cards + dot indicator + reorder via ◀▶ buttons (already index-based, no drag needed) | UI-06, **display/edit/delete/reorder only** — adding a card via camera scan (`CameraScan.jsx`) is IMP-03 (Phase 8); ship an explicit "coming soon" or manual-value fallback for "Add card" this phase, confirm with user |
| `views/Settings.jsx` (715 lines) — General/During-a-workout/Appearance/Equipment | `SettingsScreen` sections | `Row`/`SelectRow`/`Switch`/`Segmented`-equivalent (`ListTile` + custom trailing widgets) | UI-06, Phase 3 scope |
| `views/Settings.jsx` — Account (Auth/Sync rows), Notifications (push/reminder), AI Coach, Admin link | Deferred rows (hide or show disabled) | — | Phase 5 (Auth/TMR), Phase 6 (Sync), Phase 7 (Coach/Admin) |
| `views/Settings.jsx` — Data (Import from Hevy/another app, backup export/import, reset) | `SettingsScreen` "Data" section, **partial** | `GymStateRepository.exportState`/`importState` already exist (Phase 1) | Export/Import-backup/Reset ship in Phase 3 (no new logic needed — repository methods exist); Hevy/CSV smart-import is Phase 8 (IMP-01) |
| `components/TabBar.jsx` | `BottomNavigationBar`/`NavigationBar` (M3) | Home / Plan / **Start** (center, elevated) / Stats / Exercises | Start button reflects `GymState.active` (resume vs start) |
| `components/SyncBanner.jsx` | **Phase 6** | — | Needs `user`/`sync` state that doesn't exist until Phase 5/6 |
| `components/RestTimer.jsx`, `components/TimerFlash.jsx` | **Phase 5** | — | TMR-01 |
| `components/Toast.jsx` | `SnackBar` or `ToastCubit` (see UI-07 table) | | |
| `components/Modals.jsx` | Not ported — replaced by native `showModalBottomSheet`/`showDialog` | | See Architecture Pattern 3 |
| `components/ui.jsx` (`Button`, `Row`, `SelectRow`, `Switch`, `Segmented`, `Stepper`, `NumberField`, `Check`, `Slider`, `MultiSelectRow`) | `lib/core/ui_kit/` M3 widget set | `FilledButton`/`OutlinedButton`/`TextButton` variants, `ListTile`, custom `SelectRow` opening a sheet, `Switch.adaptive`, `SegmentedButton` (M3 native!), custom stepper row, `TextFormField` with `inputFormatters`, `Checkbox`/custom, `Slider` (M3 native) | `SegmentedButton` and `Slider` are M3 widgets already — no need to hand-roll those two; the rest need small custom widgets to match openGym's visual language exactly |
| `components/Icon.jsx` (82 hand-drawn icons) | `AppIcon` (`CustomPaint` + `path_drawing`) | | See Standard Stack |
| `components/LineChart.jsx` | `LineChartPainter` (`CustomPainter`) | | Port axis/gridline/gradient-fill/hover-tooltip logic (Code Examples) |
| `components/Heatmap.jsx` | `HeatmapPainter` (`CustomPainter`) or a `GridView` of coloured cells | | GitHub-style activity heatmap, NOT the muscle map |
| `components/Media.jsx` (`Thumb`) | `ExerciseMedia` widget | `Image.network` with `errorBuilder` (mirrors `onError`/`failed` state) and a minimize/expand toggle | UI-02 |
| `components/SwipeToDelete.jsx` | `Dismissible` (Flutter SDK) | | Don't hand-roll |
| `App.jsx` routes | `go_router` routes appended to `AppRoutes`/`createAppRouter()` (Phase 1) | `/home /checkin /plan /plan/r/:id /workout /stats /history /library /muscles /settings` | `/muscles`, `/coach*`, `/admin` routes deferred; `/checkin` route conditional on `S.checkIn` (already modelled: `GymState.checkIn`) |

## Common Pitfalls

### Pitfall 1: Treating `update(mut)` closures as "no state to model"
**What goes wrong:** Every mutation in openGym is an inline closure (`update(s => { s.foo = v })`)
with no named action — it is tempting to conclude "there's nothing to port for UI-07" and skip
straight to ad-hoc `setState`/repository calls per screen.
**Why it happens:** The Zustand action surface (`update`, `replaceState`) is deceptively tiny.
**How to avoid:** Model every *closure* (not action) as a Bloc event on the owning feature Bloc —
e.g. every `update(s => { s.routines.push(r) })` in `Plan.jsx` becomes a `PlanRoutineAdded` event.
**Warning signs:** A screen calling `context.read<GymStateCubit>().mutate(...)` directly from a
widget's `onPressed`, bypassing a feature Bloc entirely — defeats "logic only inside Blocs" (FND-01).

### Pitfall 2: Re-deriving `setLabel`/`exLine`/`fmtSec` math instead of just formatting
**What goes wrong:** These three functions were deliberately NOT bridged (Phase 2 summary, 02-07)
because they depend on `i18n.js` and would only produce English anyway — Phase 3 must write Dart
equivalents. The risk is writing them by re-deriving classification (is this a per-side set? is
this bodyweight?) instead of calling the already-bridged classifiers.
**Why it happens:** It's easy to eyeball `isSideSet`/`isBw`/`isPerSide` as "just a boolean check" and
re-implement the check in Dart instead of calling `WorkoutModelJs.isSideSet`/`HistoryJs.isBw`/
`HistoryJs.isPerSide` (all already bridged, confirmed in the Phase 2 summaries).
**How to avoid:** Port `setLabel`/`exLine`/`fmtSec` as thin Dart functions that call the bridge for
every classification/value decision and only hand-write the string template assembly (see Code
Examples below for the exact algorithm to mirror).
**Warning signs:** A Dart function that inspects `set.sides`/`set.mode`/`entry.target.bodyweight`
directly instead of calling a facade method.

### Pitfall 3: Building Stats' muscle-map card against a not-yet-existing `BodyMap`
**What goes wrong:** `Stats.jsx`'s `MuscleBalance` component is large (lines 100-228) and looks like
core Stats functionality; a planner unaware of the Phase 4 boundary could scope it into Phase 3 and
then block on `body-paths.js`/`CustomPainter` muscle silhouette rendering that doesn't exist yet.
**How to avoid:** Ship Stats without the "Muscle balance / Fatigue / Strength" segmented card this
phase; add a one-line comment/TODO citing MAP-01..03 where it will slot in.
**Warning signs:** A Phase 3 plan task that mentions `BodyMap`, `body-paths.js`, or muscle
fatigue/strength shading.

### Pitfall 4: Bundling the exercise media dataset as Flutter assets
**What goes wrong:** The phase description hints "ship as Flutter assets"; naively bundling the
~140 MB, non-AGPL-licensed, third-party image/GIF dataset would bloat the app, violate the
dataset's own redistribution terms (see NOTICE.md), and diverge from openGym's own mobile build.
**How to avoid:** Point `imgSrc`/`gifSrc`-equivalent Dart functions at the same pinned jsDelivr
commit openGym's `package.json` `build:mobile` script uses, fetched via `Image.network` with
Flutter's default in-memory cache.
**Warning signs:** Any task that adds `.jpg`/`.gif` files under `assets/` for exercises.

### Pitfall 5: Assuming CheckIn's "Add card" flow is fully in scope
**What goes wrong:** UI-06 lists Check-in as in-scope, but the only way to add a gym card in
openGym is scanning a barcode or importing a photo (`CameraScan.jsx`, `lib/scan.js`) — both are
IMP-03 (Phase 8). A plan that tries to build full "Add card" functionality this phase will need a
camera/barcode package that isn't mandated and isn't researched here.
**How to avoid:** Scope Check-in to list/display/QR-render/reorder/edit-name/delete of existing
cards this phase; flag "Add card via scan" as an explicit Phase 8 dependency in the plan.
**Warning signs:** A task referencing barcode scanning, `CameraScan`, or `mobile_scanner`/similar
packages in this phase's plan.

## Code Examples

### Typo-tolerant, accent-insensitive, multi-token exercise search
Verified algorithm (from `../openGym/frontend/src/lib/exercises.js`, cross-checked against
`../openGym/frontend/src/lib/search-typo.test.js`'s exact assertions):

```
// Source: ../openGym/frontend/src/lib/exercises.js (normalizeStr, corpusOf, nearWord,
// matchTokens, matchExercise, searchExercises) — port verbatim, do not "improve."

1. normalizeStr(s): NFD-normalize, strip combining diacritical marks (U+0300–U+036F), lowercase.
   (Dart: `s.toLowerCase()` after stripping diacritics — no built-in NFD normalizer in core Dart;
   a small manual diacritic-strip table or `characters`/`unicode` package MAY be needed — flag as
   an open question below if Dart's `String` has no adequate built-in for this.)

2. Per-exercise corpus (cached, keyed by an i18n "version" counter — in Phase 3, English-only, so
   the cache key can simply be a constant since there is no language switch yet):
   corpus.s = normalizeStr(join(name, target, equipment, bodyPart, secondaryMuscles, description))
   corpus.nameWords = normalizeStr(name).split(/\s+/)

3. queryTokens(query) = normalizeStr(query).split(/\s+/).filter(nonEmpty)

4. nearWord(a, b) — "one edit or adjacent transposition," restricted to name words only:
   - reject if len(a) < 5 or |len(a)-len(b)| > 1
   - walk matching prefix; if it consumes all of `a`, accept iff the length difference is ≤ 1
     (an extra trailing char in b)
   - if len(a) == len(b): accept if the single differing character can be dropped-and-match
     (substitution) OR is an adjacent transposition (swap two chars) and the rest matches
   - if len(a) != len(b) by 1: accept if skipping one char in the longer string makes the
     remainder match (insertion/deletion)

5. matchTokens(exercise, tokens, fuzzySet):
   every token must satisfy: corpus.s.contains(token)
                              OR (fuzzySet.contains(token) AND any nameWord nearWord-matches it)

6. searchExercises(list, query) — the two-pass rule that keeps correctly-spelled queries exact:
   tokens = queryTokens(query)
   fuzzy = { t in tokens : no exercise in `list` has an exact substring hit for t }
   return list.filter(e => matchTokens(e, tokens, fuzzy))

7. matchExercise(single-exercise, query) — used by pickers filtering one at a time: same as above
   but every token is allowed fuzzy fallback unconditionally (no exact-hit-anywhere check, since
   there's no "whole list" to check against).
```

Critical edge cases from `search-typo.test.js` a Dart port MUST reproduce exactly: `'dumbell bench'`,
`'dumbbel bench'`, `'dummbell bench'`, `'bnech press'`, `'presss bench'` all match "dumbbell bench
press"; `'sqat'` and `'roww'` do NOT match (short tokens excluded from fuzzy); `'wrist'` must never
fuzzy-match `'waist'` (body-part/target/equipment words are never in the fuzzy-eligible name-word
set); `searchExercises(list, 'wrist')` returns only the exact hit even when a fuzzy candidate
exists elsewhere in the list.

### `setLabel` port (calls already-bridged classifiers, hand-writes only the template)
```dart
// Source: ../openGym/frontend/src/lib/history.js:108 (setLabel) — string templating is
// presentation, not domain math (JS-04 does not apply); classification below is NOT
// re-derived, it is read from the already-bridged facades.
String setLabel(String id, SetEntryLike s, TargetConfig? cfg, WorkoutModelJs workoutModel, HistoryJs history) {
  final c = cfg ?? TargetConfig(id: id);
  final mode = history.modeOf(c); // bridged
  if (mode == 'cardio') return '${s.min ?? 0} min @ ${fmtNum(s.speed ?? 0)} km/h';
  if (mode == 'time') {
    final base = fmtSec(s.sec); // pure Dart, see below — not bridged, not math
    return (s.w ?? 0) > 0 ? '$base · ${fmtNum(s.w!)}' : base;
  }
  final bw = history.isBw(TargetConfig(id: c.id, bodyweight: c.bodyweight)); // bridged
  String oneSide(SideLike side) {
    final reps = side.r ?? 0;
    if (bw) return (side.w != null && side.w! > 0) ? '+${fmtNum(side.w!)} × $reps' : '$reps';
    return '${fmtNum(side.w ?? 0)}×$reps';
  }
  if (workoutModel.isSideSet(s)) { // bridged
    final partial = s.sides!.l.done != s.sides!.r.done;
    return ['L', 'R'].map((key) {
      final side = key == 'L' ? s.sides!.l : s.sides!.r;
      return '$key ${partial && !side.done ? '—' : oneSide(side) + effortTail(side)}';
    }).join(' · ');
  }
  return oneSide(s) + effortTail(s);
}

// Source: ../openGym/frontend/src/lib/history.js:58 (fmtSec) — pure formatting, no bridge call.
String fmtSec(num? sec) {
  final n = (sec ?? 0).round().clamp(0, 1 << 31);
  return '${n ~/ 60}:${(n % 60).toString().padLeft(2, '0')}';
}
```

### LineChart port target (axis/gridline/gradient-fill logic to mirror in `CustomPainter`)
```
// Source: ../openGym/frontend/src/components/LineChart.jsx
// Fixed viewBox width W=340, height = caller's `h`. Padding: left 34 (8 without axes), right 12,
// top 10, bottom 22 (8 without axes). Y domain: min/max of points (+ goal line if present),
// padded by 12% of range; degenerate (min==max) widens by ±1. X domain: first..last point
// timestamp. Y gridlines: "nice" step chosen from {1,2,2.5,5,10} × 10^n closest to range/3.
// X gridlines: one per calendar month crossed; falls back to 3 evenly-spaced date ticks when the
// range spans less than a month. Marked points (`m` 0..1, used for effort overlay) render as a
// circle whose radius/opacity scale with `m`. Goal line: dashed horizontal line + right-aligned
// label. Single-point series duplicates the point so the line-drawing code needn't special-case it.
```

### Heatmap port target
```
// Source: ../openGym/frontend/src/components/Heatmap.jsx
// 53 weekly columns × 7 daily cells, GitHub-style. Level (0-4) is quartile-bucketed on the
// per-day sum of workout minutes (`Math.round((end-start)/60000)` per workout, summed per day) —
// NOT sets/volume. Week start respects `GymState.weekStart` (weekStartOf). Cells with a workout
// but 0 recorded minutes still get level 1 ("something happened, just not timed"). Empty days: 0.
```

## Exercise Media (UI-02)

- Metadata (`exercises-data.js`, 888 KB, ~1300 exercises: id/n/bp/eq/tg/mg/sm/st/img/gif) is MIT
  and already effectively "vendored" the same way Phase 2 vendored `lib/*.js` — ship it as a Dart
  asset (a generated `.json` or `.dart` const, not the raw JS file) via the same
  `tool/gen_js_bundle.sh`-style reproducible script pattern, OR read it through the existing JS
  bridge's engine (it's already loaded there for `exercises.js`'s own functions) — **flag as an
  open question**: does the catalogue need a Dart-native copy for `LibraryBloc`'s search (fast,
  synchronous, no JS round-trip per keystroke) or can it live JS-side and be queried through the
  bridge? Given search runs on every keystroke and `JsEngineService.call` is async/JSON-marshalled
  per Phase 2's protocol, a **Dart-native copy is strongly recommended** for the catalogue +
  search, keeping the JS bridge exclusively for 1RM/progression/plate/recovery/history math.
- Images/GIFs: fetch from `https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@<pinned-sha>/images/{img}`
  and `.../videos/{gif}` — same pinned commit openGym's own `build:mobile` script uses
  (`7455efae41b330c265e7cd4b78dfa848e7ce5ebd` as of openGym 1.3.8; **re-verify this SHA is still
  current** before locking it, since it is an openGym release artifact, not something this
  research can independently freshness-check beyond reading `package.json`) [CITED:
  `../openGym/frontend/package.json` `build:mobile` script].
- Licensing: images/GIFs are © Gym Visual, used under the `hasaneyldrm/exercises-dataset` terms,
  NOT AGPL, NOT redistributed by openGym or this port — only linked. Carry the equivalent notice
  into this project's `NOTICE.md` (mirroring `../openGym/NOTICE.md`).
- Caching: Flutter's `Image.network` already populates `PaintingBinding.instance.imageCache`
  (in-memory, LRU, default 1000 images / 100MB) automatically — satisfies UI-02's "cached in
  memory" with zero new dependencies. No disk cache is implied by the requirement wording; if the
  user wants repeat-viewing-without-network (arguably closer to "true offline"), that is a
  `cached_network_image`-package discussion to raise explicitly, not something to add silently.

## Presentation Strings & i18n Deferral

openGym has no `locales/en.js` — the English UI strings ARE the literal arguments to `t('...')`
calls scattered through every `.jsx` file; `t()` looks up the active locale's flat dict and falls
back to the literal argument when the dict has no entry (confirmed by reading `lib/i18n-core.js`).
For Phase 3 (I18N-01/02 is Phase 8): hardcode the exact same English string literals as Dart string
constants/functions (e.g. a `t(String template, [List<Object> args])` helper that does positional
`{0}`/`{1}` substitution and nothing else — no dictionary lookup yet). This keeps every string
byte-identical to openGym's English UI today and gives Phase 8 a mechanical extraction target
(every `t('...')` call site becomes an ARB key) rather than a rewrite.

## Scope: Recommended Phase Split & Plan/Wave Structure

This phase is roughly 6x the size (by screen/line count and bridge-call surface) of any single
Phase 1/2 plan. Sequencing as one linear list of plans risks a very long, hard-to-checkpoint
execution run. Recommend the planner **emit a PHASE SPLIT** — a "Phase 3a" and "Phase 3b" — or, if
the orchestrator keeps a single Phase 3, organise it into the waves below with an explicit
mid-phase checkpoint. Rough sizing (15-18+ plans total):

**Wave 1 — Core UI kit + state foundation (blocks everything else)**
1. `GymStateCubit` (Pattern 1) + refactor point for `ShellBloc` (or a documented decision to defer
   that refactor)
2. `AppIcon` (`path_drawing` + `CustomPainter`, port all 82 icons), base M3 `ui_kit` widgets
   (`Row`, `SelectRow`, `Switch`, stepper row, `NumberField` with openGym's exact sanitization)
3. `showAppSheet`/`ToastCubit` helpers (Pattern 3)
4. `fmtNum`/`fmtDate`/`DAYN`/`MONTHS`/`weekStartOf`/`weekOrder` Dart ports (`format.js`)
5. Exercise catalogue Dart-native copy + `AppRoutes` route stubs for all Phase 3 screens

**Wave 2 — Library + exercise detail (UI-01, UI-02; smallest complete vertical slice, good first checkpoint)**
6. Typo-tolerant search port + `LibraryBloc` + `LibraryScreen`
7. `ExerciseDetailSheet` + `ExerciseMedia` (CDN fetch, in-memory cache, minimize/expand)
8. Favourites + equipment-profile filtering

**Wave 3 — Plan/Routines (UI-04; depends on Wave 1+2 for exercise picker)**
9. `PlanBloc` + `PlanScreen` (week schedule, routine list, reorder)
10. `RoutineEditBloc`/screen (`ReorderableListView`, superset linking, exercise config sheet)

**Wave 4 — Workout (UI-03; the largest wave, likely 4-6 plans on its own — candidate for its own sub-phase)**
11. `WorkoutBloc` core: start/resume, `GymState.active` lifecycle, straight-set logging
12. Warm-up/drop-set/rest-pause/per-side set editing (calls into `WorkoutModelJs`)
13. Superset grouping/navigation/reorder/swap (Pattern 2 flow-control ports)
14. Progression settings sheet, exercise picker mid-session, finish-workout flow (`finish-workout.js`)
15. Cards/List/Compact layout modes + `ExerciseBlockWidget`/`SetRowWidget` widgets

**Wave 5 — History/Stats + Home/CheckIn/Settings (UI-05, UI-06; can run partly parallel to Wave 4 once Wave 1 lands)**
16. `HistoryScreen` + `StatsCubit`/`StatsScreen` minus muscle-map card (`LineChartPainter`,
    `HeatmapPainter`)
17. `HomeScreen`
18. `CheckInScreen` (display/reorder/delete only) + `SettingsScreen` (Phase-3-owned sections only)

**Recommendation to the planner:** if the orchestrator's phase-split mechanism is available, split
after Wave 3 (Plan/Routines) — Waves 1-3 are a coherent, demoable "browse + plan" milestone; Wave 4
(Workout) plus Wave 5 (Stats/Home/Settings) is a coherent "log + review" milestone. This also
lines up with the phase's own two success criteria groupings (#1 workout logging vs. #3
Plan/History/Stats/Settings).

## Verification Strategy (No-Tests Rule)

Per CLAUDE.md, no `test/`/`*_test.dart` files or test dev-dependencies. Every requirement below
needs a concrete non-test verification method; the general project checklist
(`flutter analyze`, `bash tool/js04_audit.sh`) applies to every plan and is not repeated per row.

| Requirement | Non-test verification |
|---|---|
| UI-01 search/filter/favourite | A throwaway (uncommitted) `dart run` script feeding the exact `search-typo.test.js` query list through the ported Dart search function, asserting the same match/no-match results, printed and manually reviewed — same pattern Phase 1 used for `JsonReader` round-trip verification |
| UI-02 media caching | Manual device check: open an exercise detail sheet twice, confirm (via `flutter run --profile` or DevTools' image cache inspector) the second view does not re-fetch from network |
| UI-03 set logging (straight/warm-up/drop/rest-pause/per-side/superset) | `bash tool/run_parity.sh <device-id>` re-run (confirms the bridge calls `WorkoutBloc` now makes still match fixtures) + a scripted manual device walkthrough: start a freestyle workout, log one of each set type, finish it, confirm `workouts` table has the expected row via a throwaway `sqlite3` query against the app's database file |
| UI-03 progression suggestions match openGym | A throwaway `dart run` script that seeds a known workout history into `GymStateRepository`, calls `ProgressionJs.nextPrescription` through `WorkoutBloc`'s exact call path, and diffs the result against the same fixture openGym's own `progression.test.js` uses (already embedded in `tool/fixtures/js-parity/progression.json` from Phase 2) |
| UI-04 routine CRUD + drag reorder | Manual device check (`ReorderableListView` drag), plus `grep -c "class PlanBloc\|class RoutineEditBloc"` structural checks and a throwaway script asserting `GymStateRepository.exportState` reflects a reorder |
| UI-05 charts/heatmap render correctly | Manual device screenshot comparison against the equivalent openGym web/demo screenshot for the same seeded history (`tool/fixtures/state_sample.json` from Phase 1) |
| UI-06 Settings/Home/CheckIn options match openGym | Manual device walkthrough checklist (one screenshot per section) cross-referenced against the Screen-by-Screen Map's section list above |
| UI-07 every Zustand action has an equivalent | The Zustand Action Inventory table above IS the checklist — a plan-completion review confirms every **Phase 3** row has a corresponding Bloc event or documented native-API equivalent, and every deferred row is absent from this phase's Bloc event lists |
| UI-08 `ListView.builder`/slivers | `grep -rn "ListView(" lib/features/{library,workout,history_stats}` returns zero matches (only `ListView.builder`/`SliverList` allowed) — a mechanical grep gate, same style as Phase 1's architecture-rule verification |
| Data persists across restart | Manual device check: log a partial workout, force-stop the app, relaunch, confirm the same in-progress session resumes (exercises this phase for free via existing `GymState.active` schema, Phase 1) |

## State of the Art

| Old Approach (assumed by phase description) | Current Approach (this research) | When Changed | Impact |
|--------------------------------------------|-----------------------------------|---------------|--------|
| Ship exercise img/gif as Flutter assets | Fetch from the same pinned CDN openGym's own mobile build uses | This research (openGym `package.json` inspection) | Avoids ~140 MB asset bloat and a licensing violation; requires network for first view of any exercise |
| Port `Modals.jsx`'s sheet-stack faithfully | Use `showModalBottomSheet`/`showDialog` | This research (Flutter SDK capability review) | Large implementation-effort reduction; behaviour is platform-native rather than web-ported |
| Build Stats' full muscle-balance card this phase | Ship Stats without the `BodyMap`-based card | This research (cross-referencing ROADMAP.md Phase 4 scope) | Prevents a Phase 3 blocker on not-yet-built Phase 4 code |

**Deprecated/outdated:** None — this is a first port, not a migration of existing Flutter code.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A single `GymStateCubit` (not per-feature repositories) should be the sole writer to `GymStateRepository` | Architecture Patterns, Pattern 1 | If the user/planner prefers per-feature persistence, write races between concurrent Blocs on the flat `GymState` document become possible; needs explicit sign-off since it also implies eventually refactoring Phase 1's `ShellBloc` |
| A2 | Phase 3 workout flow ships with **no live rest/work timer** (typed-seconds only for timed sets, no countdown/beep/vibrate), deferring all of TMR-01's surface to Phase 5 | UI-07 table, Pitfall (implicit), Screen Map | If the user expects a basic in-app countdown in Phase 3 (even without background notifications), this materially changes `WorkoutBloc`'s and the Workout screen's scope; needs explicit confirmation before planning |
| A3 | CheckIn ships list/QR-display/reorder/edit/delete only, with "Add card via scan" stubbed/deferred to Phase 8 | Screen Map, Pitfall 5 | If the user wants a manual-entry "type the code" fallback in Phase 3 (openGym itself deliberately does NOT offer this, per `CheckIn.jsx`'s comments), that's a deviation from openGym's own UX the user must approve, not something to silently add |
| A4 | The exercise catalogue (`exercises-data.js`) should get a Dart-native copy for search rather than being queried through the JS bridge per keystroke | Exercise Media section | If wrong, `LibraryBloc` search latency depends on `JsEngineService.call` round-trip cost per keystroke, which Phase 2 did not benchmark for a ~1300-row/12-field-per-row corpus scan at 60fps typing speed |
| A5 | The pinned jsDelivr commit SHA (`7455efae41b330c265e7cd4b78dfa848e7ce5ebd`) from openGym 1.3.8's `package.json` is still the correct/current one to pin in this Flutter port | Exercise Media section | If openGym has since re-pinned to a newer commit (bugfixes/corrections in the dataset), the Flutter port would serve stale images; low risk (a pinned SHA, by construction, never silently changes) but should be re-checked against the current `../openGym` checkout at plan/execution time |
| A6 | `SegmentedButton` and `Slider` (Material 3 SDK widgets) are acceptable substitutes for openGym's hand-rolled `Segmented`/`Slider` controls rather than needing pixel-identical custom widgets | Screen Map (`components/ui.jsx` row) | If "layouts match openGym views 1:1" (UI-08) is read as pixel-identical custom styling rather than equivalent M3 controls, this assumption under-scopes the visual polish work |

## Open Questions

1. **Does Phase 3 need any live rest/work timer at all, even without background notifications?**
   - What we know: TMR-01..03 (Phase 5) explicitly own "the in-app rest timer" and "background
     alerts." `useUI.js`'s `startRest`/`startWork` are tightly coupled to `S.sound`/`S.timerFlash`
     settings that UI-06 asks for in Settings this phase.
   - What's unclear: whether a foreground-only countdown (no exact-background-notification, no
     wakelock) is expected as an MVP in Phase 3, or whether Settings should expose those toggles
     with no functional timer behind them yet.
   - Recommendation: confirm with the user/discuss-phase before planning `WorkoutBloc`'s scope;
     Assumption A2 above defaults to "no timer at all in Phase 3."

2. **Should the exercise catalogue be duplicated Dart-side, or always queried through the JS engine?**
   - What we know: `exercises.js`'s search functions are pure and small; the catalogue itself
     (`exercises-data.js`) is 888 KB of JSON-ish data already loaded into the QuickJS bundle for
     Phase 2's purposes (bar/history/progression modules reference exercise IDs).
   - What's unclear: whether `JsEngineService.call` round-trip latency (JSON-marshalled per Phase
     2's "safe JSON call protocol") is fast enough for live per-keystroke search over ~1300 rows,
     or whether that would visibly lag typing.
   - Recommendation: default to a Dart-native catalogue copy (Assumption A4) for `LibraryBloc`;
     the planner should schedule a throwaway benchmark (not a committed test, per the no-tests
     rule) comparing both approaches if there's any doubt.

3. **Exact CDN pin freshness.**
   - What we know: `../openGym/frontend/package.json`'s `build:mobile` script pins
     `hasaneyldrm/exercises-dataset@7455efae41b330c265e7cd4b78dfa848e7ce5ebd`.
   - What's unclear: whether this is still openGym's current pin (this repo snapshot may be older
     than the live openGym `main` branch).
   - Recommendation: re-read `../openGym/frontend/package.json` at plan/execution time and use
     whatever SHA is current then, not a value frozen in this research document.

4. **CheckIn "Add card" UX in Phase 3.**
   - What we know: openGym deliberately never offers manual code entry (comment in `CheckIn.jsx`:
     "too easy to fat-finger into a code that silently fails at the turnstile"); the only add paths
     are camera-scan and photo-import, both IMP-03/Phase 8.
   - What's unclear: whether Phase 3 should ship CheckIn with an empty "no cards yet, come back
     after Phase 8" state, or pull a minimal scan capability forward.
   - Recommendation: ship display/reorder/edit/delete only; explicitly hide/disable "Add card"
     with a phase-8 note, matching Assumption A3. Confirm with the user during discuss-phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Android emulator | Manual UI verification (`flutter analyze` cannot verify rendering) | ✓ (confirmed Phase 1/2: `emulator-5554`) | — | — |
| iOS Simulator | Manual UI verification, JS engine parity (JavaScriptCore) | ✓ (confirmed Phase 2: device UDID in `02-08-SUMMARY.md`) | — | — |
| Network access (CDN media fetch) | UI-02 exercise image/GIF loading | ✓ (confirmed in this research session: `curl` reached `pub.dev`; jsDelivr was not itself probed this session) | — | If jsDelivr is unreachable in the execution sandbox, verification of UI-02's media loading falls back to a manual device check only (already the plan for no-tests rule compliance) |
| `path_drawing` pub package | Icon rendering (`AppIcon`) | ✓ (confirmed via pub.dev API this session) | 1.0.1 | — |

**Missing dependencies with no fallback:** none identified.
**Missing dependencies with fallback:** CDN reachability (fallback = manual device verification only, consistent with the project's no-tests rule).

## Security Domain

> `security_enforcement` is absent from `.planning/config.json` → treated as enabled per protocol.
> This phase has no network auth surface (Phase 5) and no server sync (Phase 6); scope is narrow.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Out of scope — Phase 5 |
| V3 Session Management | No | Out of scope — Phase 5 |
| V4 Access Control | No | Single-user local device, no roles this phase |
| V5 Input Validation | Yes | `NumberField`-equivalent must clamp/sanitize weight/reps/effort input exactly as openGym's `commit()` does (strip non-numeric, single decimal point, negative→0 unless `nullable`); JSON from `GymStateRepository` already passes through Phase 1's `JsonReader` passthrough, no additional validation needed here |
| V6 Cryptography | No | No secrets/crypto touched this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Malformed/oversized image response from the CDN (e.g. non-image content-type, huge payload) crashing the image decoder or exhausting memory | Denial of Service | Flutter's `Image.network` + `errorBuilder` already isolates decode failures to that one widget (mirrors openGym's own `onError`→"broken tile" fallback in `Media.jsx`); no additional Dart-side validation needed beyond what `Image.network` provides |
| Unbounded typed input (e.g. pasting a huge string into a weight field) causing a parse/format exception | Denial of Service (local) | Mirror openGym's `commit()` sanitization (strip to `[0-9.,]`, single decimal point) before `num.tryParse`, never call `.parse()` (throwing) directly on raw user input |

## Sources

### Primary (HIGH confidence — read directly from source in this session)
- `../openGym/frontend/src/App.jsx` — routing table, boot sequence
- `../openGym/frontend/src/store/useStore.js`, `useUI.js` — full Zustand action inventory
- `../openGym/frontend/src/views/{Library,Plan,Home,History,Muscles,Workout,RoutineEdit,Stats,CheckIn}.jsx` — screen structure
- `../openGym/frontend/src/components/{TabBar,Toast,SyncBanner,Stepper,NumField,Media,SwipeToDelete,ui,Modals,LineChart,Heatmap,Icon}.jsx`
- `../openGym/frontend/src/lib/{exercises,search-typo.test,supersetFlow,active-workout-order,active-exercise-swap,progression-copy,glyphs,workout-controls,equipment,favourites,format,history,i18n-core}.js`
- `../openGym/frontend/package.json` (CDN pin), `../openGym/docker-compose.yml` (self-hosted media serving), `../openGym/NOTICE.md` (media licensing)
- `.planning/phases/02-core-logic-via-quickjs/02-0{5,6,7,8}-SUMMARY.md` — bridge function inventory, JS-04 enforcement precedent
- `.planning/phases/01-foundation-models/01-0{3,4,6,7}-SUMMARY.md` — existing models/repository/Bloc patterns
- `pub.dev` API (`https://pub.dev/api/packages/path_drawing`, `.../xml`) — package registry verification

### Secondary (MEDIUM confidence)
- None — all findings this session were verified against primary sources directly.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified directly against pub.dev API and the project's existing pubspec.yaml/CLAUDE.md
- Architecture: MEDIUM-HIGH — the single-`GymStateCubit` recommendation is a design proposal (Assumption A1), not something openGym's own JS dictates one specific Dart shape for
- Screen map: HIGH — every screen file was read in full or near-full this session
- Pitfalls: HIGH — each pitfall traces to a specific source-code finding in this session
- Scope boundaries (Phase 4/5/6/7/8 exclusions): HIGH — cross-referenced against ROADMAP.md's explicit phase requirement assignments

**Research date:** 2026-09-28
**Valid until:** Re-check the CDN pin SHA and `path_drawing` version at plan time; otherwise stable
for the life of this phase (no fast-moving external dependencies).
