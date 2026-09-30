# Phase 4: Muscle Map Rendering - Research

**Researched:** 2026-09-30
**Domain:** SVG geometry ingestion (xml + path_drawing) into a Flutter CustomPainter, wired to bridged JS-04 facades for load/fatigue/strength shading
**Confidence:** HIGH

## Summary

Phase 4 has two independent halves that both already have a working openGym reference and, for
one half, existing Flutter precedent to copy almost verbatim.

**Geometry (MAP-01).** `../openGym/frontend/src/lib/body-paths.js` is not XML today — it is a
plain ES module `export default {"male":{"front":{"vb":"...","p":{"chest":["d…","d…"], ...}}}, ...}`
with four views (male/front, male/back, female/front, female/back), each a viewBox string plus a
dict of muscle-slug -> list-of-path-`d`-strings. The 18 muscle slugs are `MUSCLES` in
`lib/muscles.js`; the non-muscle silhouette parts (`head, hair, neck, hands, feet, knees, ankles`)
are `INERT` and are drawn but never tappable or shaded. The requirement text mandates parsing
this with `xml` + `path_drawing`, which means the intended shape is: a one-time Node/esbuild
generator (mirroring the Phase 3 `tool/js/gen-icons.mjs` precedent) converts each of the 4 views
into a real `.svg` XML asset (`<svg viewBox="…"><path data-muscle="chest" d="…"/>…</svg>`,
INERT parts get `data-muscle="head"` etc. too, just excluded from tap targets and shading), and at
**runtime** a lazy-loaded singleton parses that asset with the `xml` package (`XmlDocument.parse`,
`findAllElements('path')`, `getAttribute`) and converts each `d` via `path_drawing`'s
`parseSvgPathData` into cached `dart:ui Path` objects, exactly mirroring openGym's own lazy
`import('../lib/body-paths.js')` + shared `CACHE`/`PENDING` singleton in `BodyMap.jsx`. This is
the only place in the whole roadmap the `xml` package (mandated in CLAUDE.md, unused so far) is
exercised — confirming this is the intended design, not just one option among several.

**Shading (MAP-02).** All the math already exists and is already bridged: `lib/muscles.js`
(`loadOf`, `loadOfWorkouts`, `levelsOf`, `rankOf`, `muscleBalanceWindow`, `musclesOf`) and
`lib/recovery.js` (`fatigueOf`, `strengthOf`) are already vendored under
`third_party/opengym/lib/` and already re-exported wholesale from `tool/js/entry.js`. However the
Dart facades only expose a subset today: `MusclesJs` (`lib/core/js/modules/muscles_js.dart`) has
`muscles`, `muscleName`, `inMuscleOrder`, `hasExplicitMuscleMetadata`, `normalizeMuscleGroups`,
`exerciseMuscleSnapshot` — it is **missing** `musclesOf`, `loadOf`/`loadOfWorkouts`,
`levelsOf`, `rankOf`, `muscleBalanceWindow`, and the `INERT` constant. `RecoveryJs` already has
`fatigueOf`/`strengthOf` (built in Phase 3.1 for a different screen) so those are directly
reusable. This means Phase 4's first wave is bridge-extension work (new facade methods + inventory
+ fixtures + parity), not UI work — exactly the "Adding a new bridged function" workflow in
`port-from-opengym/SKILL.md`.

The exact shading colors are openGym CSS, verified directly (`../openGym/frontend/src/index.css`
lines 1182-1230): the same 5-step ramp the `Heatmap` widget already implements in
`lib/core/ui_kit/heatmap.dart` (`Color.lerp(base, accent, .30/.55/.78)`, level 4 = pure accent),
with `fatigue` and `strength` view variants overriding specific levels to `red`/`orange`/`yellow`.
`AppPalette` already has every color token needed (`acc`, `red`, `orange`, `yellow`, `surface`)
**except** `label` (CSS `--label`, white in dark theme / black in light theme), which the base
silhouette/muscle fill color depends on and must be added.

**Primary recommendation:** Wave 1 = extend `MusclesJs` (+ inventory/fixtures/parity, JS-04) and
add `AppPalette.label`; Wave 2 = Node generator producing 4 SVG assets from `body-paths.js` +
runtime `xml`/`path_drawing` geometry cache + `BodyMapPainter` (CustomPainter, hit-testing via
inverse-transformed `Path.contains`); Wave 3 = wire the 3 Stats.jsx call sites (Muscle balance /
Fatigue / Strength cards, deferred from Phase 3.1) plus a new `/muscles` route +
`MuscleExplorer`-equivalent screen reusing the `LibraryBloc` filter-pipeline pattern, for MAP-03.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAP-01 | SVG path data from `body-paths.js` is parsed with `xml` + `path_drawing` into cached `Path` objects (front/back, male/female) | Confirmed `body-paths.js` is a plain JS object (not XML); recommended a build-time generator producing real SVG assets (mirroring `tool/js/gen-icons.mjs`) plus a runtime `xml`-parsing + `path_drawing`-converting lazy singleton cache (Pattern 1, Pitfall 1) |
| MAP-02 | The body map is drawn with a `CustomPainter`, with fatigue/volume shading coming from the JS recovery results | Verified exact CSS color ramp (`index.css:1182-1230`) and mapped it onto the existing `Heatmap` widget's `Color.lerp` precedent (Pattern 2); identified the missing `MusclesJs`/`AppPalette.label` bridge/token gaps that block this (Pitfalls 2, 4, 5) and confirmed `RecoveryJs.fatigueOf`/`.strengthOf` are already bridged and reusable |
| MAP-03 | User can tap a muscle to open the Muscles/MuscleExplorer view | Read `MuscleExplorer.jsx`/`Muscles.jsx` in full; confirmed no `/muscles` route exists yet; recommended reusing the `LibraryBloc` filter-pipeline shape for a new screen-scoped `MusclesBloc` (Pattern 3); documented hit-testing approach (inverse-transformed `Path.contains`, reverse paint-order) in the CustomPainter skeleton |
</phase_requirements>

<project_constraints>
## Project Constraints (from CLAUDE.md)

- **License:** AGPL-3.0-or-later — every new hand-written file/script in this phase (generator
  script, painter, bloc, screen) needs the SPDX header.
- **Mandated stack:** `xml` and `path_drawing` are both explicitly user-mandated packages;
  `path_drawing` is already installed, `xml` is net-new for this phase (see Package Legitimacy
  Audit) and is its intended point of introduction per CLAUDE.md's "later phases" note.
- **No domain math in Dart (JS-04):** all load/fatigue/strength/level/ranking calculations must
  go through `lib/core/js/opengym_js.dart` facades, extending `MusclesJs` rather than
  hand-rolling bucket/ranking logic in Dart (see Don't Hand-Roll, Pitfall 2). Verified with
  `bash tool/js04_audit.sh`.
- **No tests of any kind:** no `test/`, `integration_test/`, `*_test.dart`, no test
  dev-dependencies. Verification for this phase must rely on `flutter analyze`,
  `bash tool/js04_audit.sh`, `bash tool/run_parity.sh <device-id>` (for the new bridged
  `MusclesJs` methods), and manual/device or CLI assertion checks (e.g. comparing rendered
  shading against openGym's `index.css` color formulas, or a throwaway scratch script comparing
  `parseSvgPathData` output bounds against the source viewBox).
- **One phase at a time:** this research assumes Phase 4 waits for explicit user approval before
  execution, consistent with prior phases.
- **Bloc conventions:** any new Bloc (`MusclesBloc`) must follow the sealed
  `Equatable` state/event pattern with a single `on<Event>(_onEvent, transformer: _sequential())`
  handler, matching `LibraryBloc`/`ExercisesBloc`.
- **Feature folder layout:** the new Muscle Explorer feature must use `lib/features/muscles/{bloc,data,view}`,
  matching every other feature.
</project_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SVG path parsing (body-paths.js -> `Path`) | Client (Flutter, asset + xml/path_drawing) | Build tool (Node generator) | Geometry is static; parsing happens once, cached, on-device — no backend involvement |
| Load/fatigue/strength calculation | Core/Backend logic (QuickJS/JavaScriptCore engine, in-process) | — | JS-04: all numeric domain math stays in the bundled JS, never hand-rolled in Dart |
| Shading color mapping (level 0-4 -> Color) | Client (Flutter `CustomPainter` + `AppPalette`) | — | Presentation only; levels are ints from the bridge, color is a pure Dart/CSS-token lookup (same pattern as `Heatmap`) |
| Tap hit-testing | Client (Flutter, `CustomPainter`/`GestureDetector`) | — | Pure geometry (`Path.contains`), no domain logic |
| Muscle Explorer filtering (search/equipment/favourites) | Client (Flutter Bloc, screen-scoped) | Core/Backend logic (facade calls for `musclesOf`, catalogue) | Mirrors existing `LibraryBloc` pattern; filtering itself is Dart list ops over catalogue data, muscle-weight lookups go through the bridge |

## Package Legitimacy Audit

Only one new external package is introduced this phase: `xml`. `path_drawing` is already installed
(pubspec.yaml has `path_drawing: ^1.0.1`, used since Phase 3-03 for `AppIcon`) — no re-audit
needed for it.

```
$ pip install slopcheck --break-system-packages   # attempted, see below
```

slopcheck was not available in this environment (no network install attempted against project
policy of not silently reaching out; treat as unavailable). Per the graceful-degradation rule,
`xml` is tagged `[ASSUMED]` below and the planner must gate its install behind a
`checkpoint:human-verify` task, even though registry/version resolution was independently
verified in this session (see next paragraph) — that verification confirms the package resolves
and installs cleanly, not that it is free of supply-chain risk.

**Version verification (VERIFIED via `flutter pub add xml --dry-run`, run in this session):**
resolves to `xml: 7.1.0`, transitively adding `petitparser: 7.1.0` and bumping `meta` from
1.18.3 -> 1.19.0. No dependency conflicts were reported against the current lockfile
(`flutter_bloc`, `dio`, `retrofit`, `json_annotation`, etc.). `xml` is the canonical, long-maintained
Dart XML package (`github.com/lucashaan/xml` era name; currently maintained under the `dart-lang`
adjacent `xml` org used by countless generators) — it is the same package `flutter_svg`'s ecosystem
and most Dart codegen tooling depend on transitively.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `xml` | pub.dev | years (stable, actively maintained, v7 line) | very high (top-100 Dart package) | github.com/renggli/dart-xml | N/A — tool unavailable, treat as `[ASSUMED]` | Approved, gate behind `checkpoint:human-verify` per degradation rule |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**All packages above are `[ASSUMED]`** because slopcheck could not run — the planner must add a
`checkpoint:human-verify` task before `flutter pub add xml` executes for real.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `xml` | `^7.1.0` [ASSUMED — see audit] | Parse the generated SVG assets at runtime | Mandated in CLAUDE.md; verified to resolve cleanly against this project's lockfile |
| `path_drawing` | `^1.0.1` (already installed) [VERIFIED: pubspec.yaml] | `parseSvgPathData` converts each `d` string to a `dart:ui Path` | Already used for `AppIcon` (Phase 3-03); delegates to the mature `path_parsing` package (same parser family `flutter_svg` uses), confirmed to support cubic/quadratic/arc commands by reading `path_drawing-1.0.1/lib/src/parse_path.dart` in this session |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_bloc` / `equatable` | already installed | New `MusclesBloc`/`MuscleExplorerBloc` (screen-scoped, same shape as `LibraryBloc`) | For MAP-03's explorer screen |
| Node + esbuild (already vendored under `tool/js/node_modules`) | pinned per `tool/gen_js_bundle.sh` | Build-time generator that evaluates `body-paths.js` as an ES module and serializes it to 4 SVG XML files | Only place a new build script is needed; reuse the existing esbuild install, do not add a second one |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generating real `.svg` assets + runtime `xml` parsing | Generate a `.g.dart` file directly (like `app_icon_data.g.dart`), skipping `xml` entirely | Simpler and avoids a new dependency, but contradicts the explicit MAP-01 requirement wording ("parsed with `xml` + `path_drawing`") and CLAUDE.md's mandated-stack note that `xml` is reserved for a later phase — not recommended unless the user explicitly re-scopes MAP-01 |
| Lazy runtime parsing (cached singleton, mirroring `BodyMap.jsx`'s `CACHE`/`PENDING`) | Parse eagerly at app boot | openGym itself defers this (dynamic `import()`) specifically because the geometry is ~90 KB and only some screens show a map — match that behavior for parity of first-paint cost, not just parity of pixels |

**Installation:**
```bash
flutter pub add xml
```

## Architecture Patterns

### System Architecture Diagram

```
                     BUILD TIME (once, reproducible, like tool/gen_icons.sh)
  ../openGym/frontend/src/lib/body-paths.js (ES module, default export)
                    |
                    v
  tool/js/gen-body-paths.mjs  (Node + esbuild, evaluates the module)
                    |  serializes 4 views: male/front, male/back, female/front, female/back
                    v
  assets/body/{male,female}-{front,back}.svg   (checked-in generated assets)
                    |
   =================|============================================================
                     |                    RUNTIME (per app session)
                     v
  BodyGeometryCache (lazy singleton, mirrors BodyMap.jsx CACHE/PENDING)
    -- rootBundle.loadString(asset) --> xml.XmlDocument.parse(svg)
    -- findAllElements('path') --> getAttribute('data-muscle') + getAttribute('d')
    -- path_drawing.parseSvgPathData(d) --> dart:ui Path (grouped per muscle slug)
                    |
                    v
  BodyMapPainter (CustomPainter)
    inputs: Map<String,int> levels (0..4, from JS bridge), body ('male'|'female'), selected muscle
    draws: INERT silhouette paths (fixed fill) -> MUSCLES paths (level-colored fill, stroke=surface)
           -> selected muscle re-stroked (thicker, label color)
    hit-test: inverse-transform tap point into view-local (viewBox) space, iterate MUSCLES
              in reverse paint order, first Path.contains(point) wins -> onMuscleTap(slug)
                    ^
                    |
  GymState.workouts / .body --> JsEngineService.muscles.loadOfWorkouts/.levelsOf
                            --> JsEngineService.recovery.fatigueOf/.strengthOf   (JS-04 bridge)
                    |
                    v
  Stats screen: MuscleBalanceCard / FatigueCard / StrengthCard  (Segmented view switch)
  Muscles screen (new /muscles route): MusclesBloc (filter pipeline, like LibraryBloc)
    tap on BodyMap --> select muscle --> filter catalogue --> exercise list --> onDetail/onPlan
```

### Recommended Project Structure
```
tool/
├── js/gen-body-paths.mjs        # NEW: Node generator, esbuild + evaluate body-paths.js
└── gen_body_paths.sh            # NEW: thin wrapper (SPDX header), mirrors gen_icons.sh
assets/
└── body/
    ├── male-front.svg           # NEW generated assets (checked in, regenerate via script)
    ├── male-back.svg
    ├── female-front.svg
    └── female-back.svg
lib/core/
├── js/modules/muscles_js.dart   # EXTEND: musclesOf, loadOf, loadOfWorkouts, levelsOf,
│                                 #         rankOf, muscleBalanceWindow, INERT
├── theme/app_palette.dart       # EXTEND: add `label` color token
└── body_map/                    # NEW core module (shared by Stats + Muscles screens)
    ├── body_geometry_cache.dart # lazy singleton: xml parse + parseSvgPathData, cached Paths
    ├── body_map_painter.dart    # CustomPainter: silhouette + level-shaded muscle paths
    └── body_map.dart            # BodyMap widget (front+back row) + BodyMapLegend
lib/features/
├── stats/view/widgets/
│   └── muscle_balance_card.dart # NEW: 3-way Segmented (balance/fatigue/strength), wraps BodyMap
└── muscles/                     # NEW feature (bloc/data/view), the Muscle Explorer
    ├── bloc/muscles_bloc.dart   # screen-scoped, same shape as LibraryBloc but muscle-filtered
    ├── bloc/muscles_event.dart
    ├── bloc/muscles_state.dart
    └── view/muscles_screen.dart
```

### Pattern 1: Lazy-parsed, process-wide-cached geometry (mirrors `BodyMap.jsx`)
**What:** A single static cache holds the parsed `Path` objects per (body, view, muscle), built
once on first access and shared by every `BodyMap` widget instance (Stats' 3 cards + the Muscles
screen all show a map).
**When to use:** Always — do not reparse per widget build or per screen.
**Example:**
```dart
// Source pattern: ../openGym/frontend/src/components/BodyMap.jsx:14-27 (CACHE/PENDING)
class BodyGeometryCache {
  BodyGeometryCache._();
  static final BodyGeometryCache instance = BodyGeometryCache._();

  final Map<String, BodyViewGeometry> _cache = <String, BodyViewGeometry>{};
  Future<BodyViewGeometry>? _pending;

  Future<BodyViewGeometry> load(String body, String view) async {
    final String key = '$body-$view';
    if (_cache.containsKey(key)) return _cache[key]!;
    final String svg = await rootBundle.loadString('assets/body/$key.svg');
    final XmlDocument doc = XmlDocument.parse(svg);
    final Map<String, List<Path>> byMuscle = <String, List<Path>>{};
    for (final XmlElement el in doc.findAllElements('path')) {
      final String slug = el.getAttribute('data-muscle') ?? '';
      final String d = el.getAttribute('d') ?? '';
      (byMuscle[slug] ??= <Path>[]).add(parseSvgPathData(d));
    }
    final Rect viewBox = parseViewBox(doc.rootElement.getAttribute('viewBox')!);
    final BodyViewGeometry geo = BodyViewGeometry(viewBox: viewBox, paths: byMuscle);
    _cache[key] = geo;
    return geo;
  }
}
```

### Pattern 2: Level -> Color ramp (reuse `Heatmap`'s exact formula)
**What:** Levels 0-4 map to colors via `Color.lerp`, verified byte-for-byte against openGym's
`color-mix(in srgb, X P%, Y)` CSS function (`X` at `P%`, `Y` at `100-P%` == `Color.lerp(Y, X, P/100)`).
**When to use:** Base ("balance") view and as the fallback for levels not overridden by a variant.
**Example:**
```dart
// Source: ../openGym/frontend/src/index.css:1207-1212 (.bm-sil, .bm-m.l1..l4)
// bmBase   = color-mix(in srgb, var(--label) 11%, var(--surface))
// silhouette = color-mix(in srgb, var(--label) 18%, var(--surface))
final Color bmBase = Color.lerp(palette.surface, palette.label, 0.11)!;
final Color silhouette = Color.lerp(palette.surface, palette.label, 0.18)!;
Color levelColor(int level, Color base, Color accent) {
  switch (level) {
    case 1: return Color.lerp(base, accent, 0.32)!;
    case 2: return Color.lerp(base, accent, 0.56)!;
    case 3: return Color.lerp(base, accent, 0.78)!;
    case 4: return accent;
    default: return base;
  }
}
```

### Pattern 3: Screen-scoped filter Bloc (reuse `LibraryBloc` shape for Muscle Explorer)
**What:** `MusclesBloc` should mirror `LibraryBloc`'s `_computeState` pipeline (subscribe to
`GymStateCubit`, recompute on every state change and on local filter events) but key off a
selected muscle slug (via `MusclesJs.musclesOf(ex)[slug]`) instead of a body-part string.
**When to use:** For the `/muscles` route required by MAP-03.
**Example:** see `lib/features/library/bloc/library_bloc.dart` (existing file) — copy its
`_onStarted`/`_onGymStateChanged`/`_computeState` shape; swap the body-part filter for
`catalog.where((e) => (engine.muscles.musclesOf(e.toJson())[selectedSlug] ?? 0) > 0)`.

### Anti-Patterns to Avoid
- **Re-deriving level thresholds in Dart:** `levelsOf` (relative-max bucketing) must be called
  through the bridge, not reimplemented as `(v / max * 4).ceil()` in Dart — this is exactly the
  kind of "looks trivial" domain math JS-04 exists to prevent (rounding-mode differences between
  JS `Math.ceil` and Dart `ceil()` are usually fine, but the *rule*, not the specific risk, is
  what `tool/js04_audit.sh` enforces).
- **Parsing the SVG assets synchronously on the main isolate for every `BodyMap` build:** cache
  per Pattern 1; a `FutureBuilder`/`late` cached `Future` at the widget level, backed by the
  process-wide singleton, avoids re-parsing ~90 KB of path data on every rebuild.
- **Applying stroke width in physical/logical pixels after scaling the canvas:** SVG stroke-width
  is a user-space unit that scales with the viewBox transform. Apply `canvas.scale(sx, sy)` to fit
  the viewBox into the widget's `Size` *before* drawing, then use the literal CSS values
  (`strokeWidth: 2.5` for path outlines, `7` for the selected-muscle outline) directly — do not
  manually divide these by the scale factor, or the relative proportions will be wrong on
  different screen sizes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Effective-sets-per-muscle load, level bucketing (0-4), muscle ranking | Custom Dart aggregation over `Workout`/`SetEntry` | `MusclesJs.loadOf` / `.loadOfWorkouts` / `.levelsOf` / `.rankOf` (new facade methods, JS-04) | `loadOf` has non-obvious rules (bodyweight-exercise handling via `bodyweightKg`, `isHardSet` filtering, `SECONDARY = 0.4` weighting) already implemented and parity-tested in `lib/muscles.js` |
| Fatigue/strength decay curves | Custom half-life exponential decay math | `RecoveryJs.fatigueOf` / `.strengthOf` (already bridged) | Half-life decay constants (`FATIGUE_HALF_LIFE_MS`, `STRENGTH_HALF_LIFE_MS`, `STRENGTH_FLOOR`) are exposed as bridge getters already — do not hardcode them |
| SVG path parsing (arcs, cubics, quadratics, smooth curves) | A hand-written SVG path tokenizer | `path_drawing`'s `parseSvgPathData` (delegates to the mature `path_parsing` package) | body-paths.js path data includes elliptical-arc segments (`rx ry x-axis-rotation large-arc-flag sweep-flag x y`); a partial hand-parser will silently mis-render curves |
| Muscle-name aliasing / free-text-to-slug canonicalization | A Dart port of the `ALIAS` map in `lib/muscles.js` | `MusclesJs.musclesOf(ex)` / `.normalizeMuscleGroups(ex)` (already bridged, extend with `musclesOf`) | The alias table has ~40 entries and edge cases (custom-exercise body-part fallback, `muscleSnapshot` precedence) that are easy to drift from the JS source |

**Key insight:** every number that ends up as a shading level in this phase already has a
JS-04-compliant home in `third_party/opengym/lib/`; the actual Dart-side work for MAP-02 is thin
(read ints, pick colors), and the bulk of the risk is in MAP-01's geometry pipeline and in getting
the JS-04 facade extension done correctly and parity-verified.

## Common Pitfalls

### Pitfall 1: Treating `body-paths.js` as if it were already SVG/XML
**What goes wrong:** Assuming the vendored file can be fed straight to the `xml` package.
**Why it happens:** The requirement text says "SVG path data ... parsed with `xml`", which reads
as if an `.svg` file already exists somewhere.
**How to avoid:** Confirmed by reading the file directly this session — it is a plain JS object
literal (`export default {...}`), ~90 KB, no XML anywhere. A generator step (Node/esbuild,
following the `tool/js/gen-icons.mjs` precedent from Phase 3-03) must synthesize the SVG XML
assets first.
**Warning signs:** Any plan task that says "parse `third_party/opengym/lib/body-paths.js` with the
`xml` package" directly is wrong — it must say "with a generator producing SVG assets, then parse
those assets with `xml`".

### Pitfall 2: Missing `MusclesJs` facade methods block MAP-02 entirely
**What goes wrong:** Starting the `CustomPainter`/UI work before checking that
`musclesOf`/`loadOfWorkouts`/`levelsOf`/`rankOf`/`muscleBalanceWindow`/`INERT` exist on the
Dart side — they do not (verified by reading `lib/core/js/modules/muscles_js.dart` in full this
session). `entry.js` already re-exports the whole `muscles.js` namespace (`export * as muscles`),
so the JS engine *can* answer these calls today, but there is no typed Dart wrapper, no
`bridge-inventory.mjs` entry, and no parity fixture for them yet.
**Why it happens:** Easy to assume "the module is already bridged" from seeing `MusclesJs` exists.
**How to avoid:** Wave 1 task: add to `tool/js/bridge-inventory.mjs`'s `muscles` entry —
`functions: [..., 'musclesOf', 'loadOf', 'loadOfWorkouts', 'loadOfActive', 'loadOfRoutine',
'levelsOf', 'rankOf', 'muscleBalanceWindow']`, `constants: ['MUSCLES', 'MUSCLE_NAME', 'INERT']`
— then typed methods in `muscles_js.dart`, fixture cases, dispatch cases, and
`bash tool/run_parity.sh <device-id>`.
**Warning signs:** `bash tool/js04_audit.sh` failing, or a plan task that writes bucket/ranking
math directly in a new `.dart` file under `lib/features/stats` or `lib/core/body_map`.

### Pitfall 3: `recovery-view.js`'s `fatigueStateOf` boundary function is not vendored
**What goes wrong:** The Fatigue card's status label ("Ready"/"Recovering"/"Fatigued") calls
`fatigueStateOf(value)` in openGym, defined in `lib/recovery-view.js` — a file that is **not**
in `third_party/opengym/lib/` today (only `recovery.js` is vendored; confirmed by listing the
vendored directory this session). It is a tiny (15-line) boundary check against
`FATIGUE_STATES` (already bridged via `RecoveryJs.fatigueStates`).
**How to avoid:** Vendor `recovery-view.js` (same `tool/gen_js_bundle.sh --sync` + manifest flow
used for `backfill.js`/`units.js` in Plan 03.1-01), export it from `entry.js`, add a
`fatigueStateOf` method to `RecoveryJs`, rather than hardcoding the `.25`/`.5` boundaries in Dart.
**Warning signs:** A Dart `if (value < 0.25) ...` comparison anywhere in the Stats/muscle-map code.

### Pitfall 4: `FATIGUE_LEVELS`/`STRENGTH_LEVELS` thresholds are UI constants, not lib exports
**What goes wrong:** Searching `third_party/opengym/lib/recovery.js` for `FATIGUE_LEVELS` and not
finding it, then assuming the thresholds must be computed some other bridged way.
**Why it happens:** These arrays (`[{at:0,level:0},{at:.15,level:1},...]`) are defined directly in
`../openGym/frontend/src/views/Stats.jsx` (lines ~44-58), not in any `lib/*.js` module — they are
literal, hand-authored UI configuration (absolute shading bands passed as the `thresholds` param
to `BodyMap`/`levelsOf`), not derived domain math.
**How to avoid:** Port them as plain Dart constants (`const List<ThresholdRule> kFatigueLevels =
[...]`) with a source citation comment, exactly like the Heatmap widget already hardcodes its own
level-to-opacity constants. This is not a JS-04 violation because nothing is *calculated* — the
values are copied verbatim and then passed into the already-bridged `levelsOf(load, thresholds)`
call.
**Warning signs:** None if the values are copied exactly: `at: 0/0.15/0.25/0.4/0.55` for fatigue,
`at: STRENGTH_FLOOR/0.625/0.75/0.875/1` for strength (`STRENGTH_FLOOR` itself must come from
`RecoveryJs.strengthFloor`, already bridged — do not hardcode that one).

### Pitfall 5: `AppPalette` has no `label` token yet
**What goes wrong:** `--bm-base` and `.bm-sil` both key off `var(--label)` (white in dark theme,
`#000000` in light theme per `../openGym/frontend/src/index.css:29,71`), but
`lib/core/theme/app_palette.dart` (read in full this session) has no `label` field — only
`muted`/`dim` (mapped from `--label-2`/`--label-3`).
**How to avoid:** Add `label` to `AppPalette` (`Colors.white` for `.dark()`, `Colors.black` for
`.light()`) as a constructor field, update `copyWith`/`lerp`/`cssVar` accordingly — same pattern
as every other token in that file.
**Warning signs:** Any inline `Theme.of(context).brightness == Brightness.dark ? Colors.white :
Colors.black` conditional in the muscle-map painter instead of a palette field — that duplicates
the theme model rather than extending it.

### Pitfall 6: Overlapping muscle paths and paint-order hit-testing
**What goes wrong:** Some muscle regions may visually overlap at boundaries (adjacent SVG shapes
with slight coordinate overlap is common in hand-traced anatomical art); a naive "first `MUSCLES`
entry whose Path.contains(point) is true" hit test can pick the wrong (visually-hidden) muscle.
**How to avoid:** Iterate `MUSCLES` in **reverse** draw order for hit-testing (last-painted =
topmost, matches browser pointer-events z-order semantics that `BodyMap.jsx`'s SVG relies on
implicitly) — first reverse-order match wins.
**Warning signs:** Tapping near a muscle boundary and having the tap register on the wrong,
adjacent muscle inconsistently between front/back or male/female views.

## Code Examples

### Extending the JS-04 bridge for muscle load/levels (Wave 1, before any UI work)
```dart
// lib/core/js/modules/muscles_js.dart — additions
// Source: ../openGym/frontend/src/lib/muscles.js (musclesOf, loadOf, loadOfWorkouts,
// levelsOf, rankOf, muscleBalanceWindow, INERT)

Map<String, double> musclesOf(Map<String, Object?> ex) {
  final Object? res = _engine.call('muscles.musclesOf', <Object?>[ex]);
  return jsDoubleMap(res, 'muscles.musclesOf');
}

Map<String, double> loadOfWorkouts(List<Workout> workouts, {bool? hardOnly}) {
  final Object? res = _engine.call('muscles.loadOfWorkouts', <Object?>[
    workouts.map((Workout w) => w.toJson()).toList(),
    hardOnly == true ? jsUndefined /* pass isHardSet predicate name if needed */ : jsUndefined,
  ]);
  return jsDoubleMap(res, 'muscles.loadOfWorkouts');
}

Map<String, int> levelsOf(Map<String, double> load, {List<Map<String, Object?>>? thresholds}) {
  final Object? res = _engine.call('muscles.levelsOf', <Object?>[load, thresholds ?? jsUndefined]);
  return jsIntMap(res, 'muscles.levelsOf');
}

List<String> get inert => jsStringList(_engine.read('muscles.INERT'), 'muscles.INERT');
```
*(`loadOfWorkouts`'s second parameter in JS is a `pick` predicate function, not serializable JSON —
this needs a small server-side `finish`-style shim, or a boolean flag interpreted inside a shim
wrapper in `tool/js/shims/`, similar to `view-aggregates-shim.js`. Confirm exact call shape during
planning by reading `../openGym/frontend/src/lib/muscles.js:loadOfWorkouts` signature — it takes
`(workouts, pick)` where `pick` filters `SetEntry`; a `hardOnly: bool` flag translated to
`isHardSet`/`null` inside a new `muscles-shim.js` mirrors the `finish-workout-shim.js` pattern.)*

### CustomPainter hit-testing skeleton
```dart
// lib/core/body_map/body_map_painter.dart
class BodyMapPainter extends CustomPainter {
  BodyMapPainter({required this.geometry, required this.levels, required this.palette, this.selected});
  final BodyViewGeometry geometry;      // viewBox + Map<String, List<Path>>
  final Map<String, int> levels;        // muscle slug -> 0..4
  final AppPalette palette;
  final String? selected;

  Matrix4 _fitTransform(Size size) {
    final double sx = size.width / geometry.viewBox.width;
    final double sy = size.height / geometry.viewBox.height;
    return Matrix4.identity()
      ..scale(sx, sy)
      ..translate(-geometry.viewBox.left, -geometry.viewBox.top);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final Matrix4 m = _fitTransform(size);
    canvas.transform(m.storage);
    // 1. INERT silhouette paths (fixed fill, no stroke variation)
    // 2. MUSCLES paths, fill = levelColor(levels[slug] ?? 0, ...), stroke = surface, width 2.5
    // 3. If selected != null: re-stroke that muscle's paths, stroke = label, width 7
    canvas.restore();
  }

  Offset? hitTest(Offset localPosition, Size size) {
    final Matrix4 inverse = Matrix4.inverted(_fitTransform(size));
    final Offset local = MatrixUtils.transformPoint(inverse, localPosition);
    return local; // then iterate MUSCLES.reversed, check geometry.paths[slug]!.any((p) => p.contains(local))
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter old) =>
      old.levels != levels || old.selected != selected || old.geometry != geometry;
}
```

## Runtime State Inventory

*Not applicable — this is a greenfield phase (new geometry cache, new painter, new bridge
methods, new screen), not a rename/refactor/migration.*

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `xml` package (v7.1.0) is legitimate and safe to install | Package Legitimacy Audit, Standard Stack | Low — resolution verified in this session via real `flutter pub add --dry-run`, and it is one of the most widely depended-on Dart packages; slopcheck simply could not run to give a formal `[OK]`. Planner should still gate behind `checkpoint:human-verify` per the degradation rule. |
| A2 | The intended MAP-01 design is "generate real SVG assets, then parse at runtime with `xml`" rather than "generate a `.g.dart` file directly" | Summary, Architecture Patterns, Pitfall 1 | Medium — this is inferred from the requirement wording + the CLAUDE.md note that `xml` is reserved for a later phase, not directly confirmed by a CONTEXT.md decision (none exists for this phase). If wrong, the generator step still produces correct geometry, just via a different file format; replanning cost is one task, not a redesign. |
| A3 | `loadOfWorkouts`'s `pick` (predicate) parameter needs a small shim (non-JSON-serializable function argument) rather than being callable directly over the JSON bridge | Code Examples | Medium — if the existing bridge call protocol already supports passing a named-predicate string/flag some other way (unconfirmed — not verified against `JsEngineService.call`'s actual argument marshalling this session), the shim may be unnecessary. Planner/executor must check `lib/core/js/js_engine_service.dart`'s call protocol before writing the shim. |

## Open Questions (RESOLVED)

1. **Exact viewBox scaling behavior for hit-testing when front/back are shown side-by-side vs stacked**
   - What we know: `.bodymap` in openGym CSS renders two `<svg class="bm-v">` (front, back), and
     `bm-v` has `flex:1; height:auto; max-height:min(46vh,340px)` — implying a row layout, each
     view scaled to fit its half-width while preserving aspect ratio (viewBox-driven).
   - What's unclear: The exact Flutter layout (`Row` of two `AspectRatio`-wrapped painters vs. a
     single painter drawing both) was not confirmed against a full CSS layout trace in this
     session.
   - Recommendation: Planner should have the executor re-read the `.bodymap`/`.bm-v` CSS rules in
     full (`index.css` around line 1197-1230) during Wave 2 and pick `Row(children: [Expanded(front), Expanded(back)])`
     with `AspectRatio(aspectRatio: viewBox.width/viewBox.height)` per view, matching CSS behavior.
   - RESOLVED: 04-04 Task 2 uses a front/back row (6 px gap), each view's height = width × viewBox aspect,
     capped at min(46% screen height, 340 px), uniform "meet" fit centred; paint and hit-test share `BodyMapFit`.

2. **Whether `loadOfWorkouts`'s `pick` predicate is reachable over the existing JSON call bridge**
   - What we know: `RecoveryJs.fatigueOf`/`strengthOf` pass whole `Workout` lists and an `opts`
     object (no function arguments) — every other bridged call in the codebase passes only
     JSON-serializable data.
   - What's unclear: Whether `_engine.call` supports passing a function reference at all, or
     whether the standard pattern (per `finish-workout-shim.js`/`view-aggregates-shim.js`) is
     always "write a small JS shim in `tool/js/shims/` that hardcodes the specific predicate
     (`isHardSet`) and exposes a boolean-flag API instead."
   - Recommendation: Follow the shim pattern (confirmed precedent, safe default) rather than
     attempting to marshal a function across the bridge.
   - RESOLVED: 04-01's `muscle-view-shim.js` `muscleBalance(S, win, hard, nowMs, todayIso)` takes a `hard`
     boolean and passes `isHardSet` itself; Dart `MusclesJs.loadOfWorkouts` always sends `jsUndefined` for `pick` (04-02).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `xml` (pub package) | MAP-01 asset parsing | Verified resolvable | 7.1.0 (dry-run resolution) | none needed — resolves cleanly |
| `path_drawing` (pub package) | MAP-01 Path conversion | Already installed | 1.0.1 | none needed |
| Node + esbuild (`tool/js/node_modules`) | Build-time SVG generator | Already present (used by `gen_icons.sh`/`gen_js_bundle.sh`) | pinned per existing tooling | none needed |
| Android emulator / iOS simulator | Device verification, `tool/run_parity.sh` | Not probed this session (no device attached to research environment) | — | Executor must run `tool/run_parity.sh <device-id>` during Wave 1/2 execution, per project convention |

**Missing dependencies with no fallback:** none identified.
**Missing dependencies with fallback:** none identified (device availability is an execution-time
concern already handled by the project's standing verification workflow, not a phase-planning
blocker).

## Security Domain

`security_enforcement` is not set in `.planning/config.json` (absent = enabled), but this phase
has no user input, network calls, authentication, or persistence surface — it draws from
already-validated `GymState` data and static bundled assets. No new ASVS categories apply beyond
what Phase 1-3 already cover (input validation of `GymState` fields, none of which changes here).

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no (asset is build-time generated from a trusted vendored source, not user input) | — |
| V6 Cryptography | no | — |

### Known Threat Patterns for this stack
None specific to this phase — no new trust boundary is introduced (SVG assets are generated at
build time from the already-vendored, checksum-manifested `third_party/opengym` source tree, not
fetched or parsed from an untrusted runtime source).

## Sources

### Primary (HIGH confidence)
- `../openGym/frontend/src/components/BodyMap.jsx` (read in full) — component structure, lazy-load pattern, `load`/`thresholds`/`body`/`onMuscle`/`selected` API
- `../openGym/frontend/src/lib/body-paths.js` (read header + verified structure via a throwaway `node -e` import in this session) — confirmed plain JS object, not XML; confirmed 4 viewBoxes and part-key lists per view
- `../openGym/frontend/src/lib/muscles.js` (read in full) — `MUSCLES`, `INERT`, `MUSCLE_NAME`, `musclesOf`, `loadOf`, `loadOfWorkouts`, `levelsOf`, `rankOf`, `muscleBalanceWindow`
- `../openGym/frontend/src/lib/recovery-view.js` (read in full) — `fatigueStateOf`, confirmed NOT in `third_party/opengym/lib/`
- `../openGym/frontend/src/views/Stats.jsx` (read `MuscleBalance`/`FATIGUE_LEVELS`/`STRENGTH_LEVELS` sections) — call sites, view-local threshold constants
- `../openGym/frontend/src/components/MuscleExplorer.jsx` and `../openGym/frontend/src/views/Muscles.jsx` (read in full) — MAP-03 target screen
- `../openGym/frontend/src/index.css` lines 1182-1230 (grepped directly) — exact `.hm-c`/`.bm-*` color formulas for all 3 view variants (balance/fatigue/strength)
- `lib/core/js/modules/muscles_js.dart`, `lib/core/js/modules/recovery_js.dart`, `lib/core/js/opengym_js.dart`, `tool/js/entry.js`, `tool/js/bridge-inventory.mjs`, `third_party/opengym/lib/` directory listing (all read/grepped in this session) — confirmed current bridge coverage gaps
- `lib/core/theme/app_palette.dart`, `lib/core/ui_kit/heatmap.dart` (read in full) — confirmed color-ramp precedent and missing `label` token
- `lib/core/router/*.dart` (read in full) — confirmed no `/muscles` route exists yet
- `.planning/phases/03-bloc-ui-translation/03-03-PLAN.md` (read in full) — direct precedent for a Node/esbuild generator producing checked-in Dart/asset artifacts from openGym JSX/JS source (`gen-icons.mjs`)
- `/Users/apple/.pub-cache/.../path_drawing-1.0.1/lib/src/parse_path.dart` (read in full) — confirmed `parseSvgPathData` delegates to the mature `path_parsing` package (handles arcs/cubics/quadratics)
- `flutter pub add xml --dry-run` (run in this session) — confirmed clean resolution at `xml: 7.1.0`

### Secondary (MEDIUM confidence)
- WebSearch on `xml` package API (`XmlDocument.parse`, `findAllElements`, `getAttribute`) — corroborates training knowledge, standard well-known API surface, not independently re-verified against v7.1.0 changelog

### Tertiary (LOW confidence)
- None — every load-bearing claim above was verified against either the vendored openGym source, the current Flutter codebase, or a live tool invocation in this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `path_drawing` already installed and inspected directly; `xml` version verified via live dry-run resolution
- Architecture: HIGH — every pattern (lazy cache, color ramp, filter-Bloc) has a direct, already-implemented precedent in this exact codebase (`BodyMap.jsx`, `Heatmap`, `LibraryBloc`)
- Pitfalls: HIGH — every pitfall was discovered by direct inspection of current repo state (missing facade methods, missing `label` token, missing route, un-vendored `recovery-view.js`), not speculation

**Research date:** 2026-09-30
**Valid until:** 30 days (stable internal codebase + a long-stable pub package; re-check `xml`'s
resolved version if `flutter pub get` is run much later, since dependency resolution can shift with
other pubspec changes in the interim)
