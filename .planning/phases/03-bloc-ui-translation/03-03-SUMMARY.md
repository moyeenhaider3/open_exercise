# Phase 3 Plan 03: Presentation Foundation Summary

Delivered presentation primitives required by openGym screens: `AppIcon` rendered with `path_drawing` from openGym's `Icon.jsx` path data, the `t()` string localization helper, Dart presentation ports of `format.js`, `glyphs.js`, and `workout-controls.js`, and `setLabel`/`exLine`/`fmtSec` with bridged domain classifications.

## Delivered Artifacts

### 1. openGym Icon Set & Generator
- Added `path_drawing: ^1.0.1` to [pubspec.yaml](file:///Users/apple/projects/learning-project/open_exercise/pubspec.yaml).
- Created [tool/js/gen-icons.mjs](file:///Users/apple/projects/learning-project/open_exercise/tool/js/gen-icons.mjs) and wrapper [tool/gen_icons.sh](file:///Users/apple/projects/learning-project/open_exercise/tool/gen_icons.sh).
  - Evaluates `../openGym/frontend/src/components/Icon.jsx` via esbuild with a custom JSX recording factory.
  - Extracts all 88 icons and aliases in openGym's canonical `ICON_NAMES` order.
  - Output icon count: Node `ICON_NAMES.length` = 88, generated `kIconNames.length` = 88 (exact match).
  - Source file SHA256: `6ed7ee3f6c6f` recorded in generated header.
  - Generates [lib/core/ui_kit/icons/app_icon_data.g.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/icons/app_icon_data.g.dart).
  - Re-run diff verification: `git diff --stat` is clean on re-generation (100% reproducible).
- Created [lib/core/ui_kit/icons/app_icon.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/icons/app_icon.dart):
  - `AppIcon` widget utilizing a `CustomPainter` with `parseSvgPathData`.
  - Ambient 24x24 viewBox scaling, default stroke width 1.7, `StrokeCap.round`, `StrokeJoin.round`.
  - Element cache to avoid re-parsing SVG strings on every frame.
  - Wrapped in `ExcludeSemantics`. Unknown icon names safely render `SizedBox.shrink()`.

### 2. Formatting, Glyphs, and Controls Ports
- Created [lib/core/i18n/t.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/i18n/t.dart):
  - Positional template formatter matching `i18n-core.js` `t(template, args)`.
- Created [lib/core/format/format.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/format/format.dart):
  - 25 explicit `Ported from ../openGym/frontend/src/lib/format.js` citations.
  - Pure presentation formatting: `todayIso()`, `isoOf()`, `kDayNames`, `kDayShort`, `kMonths`, `kMonthsLong`.
  - `fmtDate()` matching `en-GB` `toLocaleDateString` behavior (including `Sept` abbreviation).
  - `fmtNum()` matching JavaScript `Math.round` half-to-positive-infinity semantics and `en-GB` comma grouping.
  - `setWeightDecimals()`, `weightDecimals()`, `fmtVol()`, `exCount()`, `routineCount()`.
  - Week helpers: `kMonday`, `kSunday`, `weekStartOf()`, `weekOrder()`, `weekDayOffset()`, `startOfWeek()`, `weekKey()`, `uid()`, `kAccents`.
- Created [lib/core/format/glyphs.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/format/glyphs.dart):
  - `kDefaultGlyph`, `kGlyphGroups`, `kGlyphs`, `glyphOf()` with legacy emoji and ZWJ/variation-selector stripping.
- Created [lib/core/format/workout_controls.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/format/workout_controls.dart):
  - `kWcDefault` and `workoutControls(GymState?)` overlaying `GymState.wc`.

### 3. Bridged Set and Exercise Labels
- Created [lib/core/format/set_label.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/format/set_label.dart):
  - `fmtSec(num? sec)` for seconds duration formatting (`m:ss`).
  - `setLabel(engine, id, s, cfg)` mirroring openGym `history.js:108`.
  - `exLine(engine, cfg, unit)` mirroring openGym `history.js:140`.
  - All classifications bridged (zero Dart math/re-derivation):
    - `engine.history.modeOf(cfg)`
    - `engine.history.isBw(cfg)`
    - `engine.history.isPerSide(cfg)`
    - `engine.history.sideReps(reps)`
    - `engine.history.effort`
    - `engine.workoutModel.isSideSet(s)`
  - Reads `sec`, `min`, `speed` from `s.extra` / `cfg.extra` without importing `model_extras.dart`.

## Parity Verification Side-by-Side

Comparing Node.js execution against the Dart port across 30+ numeric and date inputs:

```
=== wdec 1 ===
Node: 0 => 0                    | Dart: 0 => 0
Node: 0 => -0                   | Dart: -0.0 => -0
Node: 0.05 => 0.1               | Dart: 0.05 => 0.1
Node: 0.04 => 0                 | Dart: 0.04 => 0
Node: 2.45 => 2.5               | Dart: 2.45 => 2.5
Node: 2.5 => 2.5                | Dart: 2.5 => 2.5
Node: -2.5 => -2.5              | Dart: -2.5 => -2.5
Node: 62.5 => 62.5              | Dart: 62.5 => 62.5
Node: 7535 => 7,535             | Dart: 7535 => 7,535
Node: -0.5 => -0.5              | Dart: -0.5 => -0.5
Node: 1234567.891 => 1,234,567.9| Dart: 1234567.891 => 1,234,567.9
Node: 1000 => 1,000             | Dart: 1000 => 1,000
Node: 1000000 => 1,000,000      | Dart: 1000000 => 1,000,000
Node: -1000.5 => -1,000.5       | Dart: -1000.5 => -1,000.5
Node: 0.25 => 0.3               | Dart: 0.25 => 0.3
Node: 0.75 => 0.8               | Dart: 0.75 => 0.8
Node: 15 => 15                  | Dart: 15 => 15
Node: 12.345 => 12.3            | Dart: 12.345 => 12.3
Node: -12.345 => -12.3          | Dart: -12.345 => -12.3
Node: 99.99 => 100              | Dart: 99.99 => 100
Node: -99.99 => -100            | Dart: -99.99 => -100
Node: 1 => 1                    | Dart: 1.0 => 1
Node: 0.001 => 0                | Dart: 0.001 => 0
Node: 1000000000 => 1,000,000,000 | Dart: 1000000000 => 1,000,000,000
Node: NaN => NaN                | Dart: NaN => NaN
Node: Infinity => ∞             | Dart: Infinity => ∞
Node: -Infinity => -∞           | Dart: -Infinity => -∞

=== wdec 2 ===
Node: 1234567.891 => 1,234,567.89 | Dart: 1234567.891 => 1,234,567.89
Node: 0.25 => 0.25              | Dart: 0.25 => 0.25
Node: 0.75 => 0.75              | Dart: 0.75 => 0.75
Node: 12.345 => 12.35           | Dart: 12.345 => 12.35
Node: -12.345 => -12.34         | Dart: -12.345 => -12.34

=== fmtDate ===
2026-09-28 short: 28 Sept        | 2026-09-28 short: 28 Sept
2026-09-28 long: Mon 28 Sept     | 2026-09-28 long: Mon 28 Sept
2026-09-28 short+yr: 28 Sept 2026| 2026-09-28 short+yr: 28 Sept 2026
2026-09-28 long+yr: Mon, 28 Sept 2026 | 2026-09-28 long+yr: Mon, 28 Sept 2026
2026-01-05 short: 5 Jan          | 2026-01-05 short: 5 Jan
2026-01-05 long: Mon 5 Jan       | 2026-01-05 long: Mon 5 Jan
2026-05-15 short: 15 May         | 2026-05-15 short: 15 May
2026-05-15 long: Fri 15 May      | 2026-05-15 long: Fri 15 May
```

## Verification

1. **JS-04 Audit:** `bash tool/js04_audit.sh` -> PASS
2. **Static Analysis:** `flutter analyze` -> No issues found!
3. **Reproducibility:** `bash tool/gen_icons.sh` leaves no git diff.
