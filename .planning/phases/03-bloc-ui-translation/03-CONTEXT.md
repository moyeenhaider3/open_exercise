# Phase 3: BLoC & UI Translation - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning
**Source:** User answers to 03-RESEARCH.md open questions and assumptions (plan-phase orchestrator)

<domain>
## Phase Boundary

Phase 3 delivers the state layer plus the Library, exercise detail, active Workout, and Plan/RoutineEdit screens (UI-01..UI-04), with UI-07 (Zustand → Bloc mapping) and UI-08 (builder lists, 1:1 layouts) applied to those screens.

History, Stats, Home, Check-in and Settings (UI-05, UI-06) moved to **Phase 3.1** (inserted). Phase 3 must still build the shared state and persistence they will reuse.

</domain>

<decisions>
## Implementation Decisions

### Scope split
- D-01: Phase 3 is split after Plan/Routines. Phase 3 = state layer, Library (UI-01), exercise detail (UI-02), Workout (UI-03), Plan + RoutineEdit (UI-04), and UI-07/UI-08 for those screens. Phase 3.1 = History, Stats, Home, Check-in, Settings (UI-05, UI-06).

### Timers
- D-02: No rest/work timer of any kind in Phase 3, not even a foreground one. Timers, sound and background alerts belong to Phase 5 (TMR-01..03). Any timer control in openGym's Workout view is left out or shown as a non-functional placeholder, as stated in the plan.
- D-02a: The active-workout header's elapsed session clock (a passive `m:ss` display computed from the workout start time, with no alerts) is kept. The user confirmed this on 2026-09-28.

### Plan sharing
- D-06: openGym's Plan-header "Share your plan" (export, print and import plan files) is deferred to Phase 8 (IMP-04). It needs plugins outside the mandated stack. The UI-07 checklist records it as deferred. The user confirmed this on 2026-09-28.

### Check-in
- D-03: When Check-in is built (Phase 3.1), it ships display/reorder/edit/delete only. "Add card" is deferred to Phase 8 (barcode scanning, IMP-03). Recorded here so Phase 3's state layer does not need to support card creation.

### State architecture
- D-04: A single `GymStateCubit` is the only writer of persisted gym state. Its `mutate()` mirrors openGym's `useStore.update()`, `replaceState()` mirrors `replaceState()`, and it persists via `GymStateRepository`. Feature Blocs/Cubits read from it and dispatch mutations through it; they never write persistence themselves.
- D-05: `useUI.js` sheet/toast/modal actions map to native Flutter Navigator APIs (`showModalBottomSheet`, `showDialog`, `ScaffoldMessenger`). They are not reimplemented as a custom sheet-stack Bloc. The UI-07 checklist records each mapping.

### Claude's Discretion
- Exercise catalogue access for search/filter (Dart-native copy of the data versus querying through the JS bridge). The research recommends a Dart-native data copy. Any typo-tolerant search algorithm that lives in openGym `lib/` must still run via JS, or be justified as non-math under JS-04.
- Exercise media: load from openGym's pinned CDN via `Image.network` and Flutter's in-memory `ImageCache`, per research. Re-check the pinned commit SHA against `../openGym/frontend/package.json` at execution time.
- Drag-to-reorder via `ReorderableListView` / `SliverReorderableList`. Do not port openGym's hand-rolled drag system.
- Porting the flow-control modules (`supersetFlow.js`, `active-workout-order.js`, `active-exercise-swap.js`) directly to Dart with source citations. These are not domain math.
- Plan/wave decomposition within Phase 3.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/03-bloc-ui-translation/03-RESEARCH.md`: screen map, Zustand inventory (UI-07 checklist), JS facade needs, pitfalls, verification strategy
- `.claude/skills/port-from-opengym/SKILL.md`: porting workflow, JS-04 rule, app patterns
- `../openGym/frontend/src/views/{Library,Workout,Plan,RoutineEdit}.jsx`, `../openGym/frontend/src/sheets.jsx`, `../openGym/frontend/src/components/`: the UI spec (no UI-SPEC.md, user decision)
- `../openGym/frontend/src/store/useStore.js`, `useUI.js`: UI-07 source
- `lib/core/js/opengym_js.dart`: JS facades (Phase 2)
- `lib/core/data/gym_state_repository.dart`, `lib/core/models/`: persistence and models (Phase 1)

</canonical_refs>

<specifics>
## Specific Ideas

- The success criterion "Progression suggestions shown in the UI match openGym" is proven by calling `ProgressionJs` (parity already proven in Phase 2), not by any Dart math.
- No tests (project rule). Verification uses `flutter analyze`, `bash tool/js04_audit.sh`, grep/source assertions, and manual device checks.

</specifics>

<deferred>
## Deferred Ideas

- Timers, sound and background rest alerts: Phase 5
- History, Stats, Home, Check-in, Settings screens: Phase 3.1
- Stats muscle-balance/fatigue card (needs BodyMap): Phase 4
- Check-in "Add card" (barcode): Phase 8
- i18n beyond English source strings: Phase 8

</deferred>

---

*Phase: 03-bloc-ui-translation*
*Context gathered: 2026-09-28 via plan-phase orchestrator (user answers)*
