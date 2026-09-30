# Plan 04-04 Summary: Body Geometry Cache, BodyMapPainter & BodyMap Widget

## Executive Summary
Plan `04-04` built the shared native body map rendering system, connecting parsed SVG XML assets to native Flutter custom painting, level-based shading, tap hit-testing, and legends:
- **AppPalette.label Token**: Added `label` token (`#FFFFFF` in dark, `#000000` in light) to `AppPalette` with full copyWith/lerp/cssVar support, avoiding brightness conditionals in painting code.
- **BodyGeometryCache**: Implemented lazy singleton `BodyGeometryCache` that parses `assets/body/*.svg` using `xml` and `path_drawing`'s `parseSvgPathData` into immutable `Path` geometries for front and back views (male and female). Shared process-wide; includes synchronous `peek()` so already-cached geometry paints immediately without placeholder flicker.
- **BodyMapPainter & Color System**:
  - `BodyMapVariant` (`balance`, `fatigue`, `strength`).
  - `BodyMapColors` transcribing openGym's `index.css:1201-1230` color-mix formulas via `Color.lerp`:
    - Base: `Color.lerp(surface, label, 0.11)`.
    - Silhouette: `Color.lerp(surface, label, 0.18)`.
    - Balance: l1-l3 lerped with `acc` (0.32/0.56/0.78), l4 = `acc`.
    - Fatigue: l1 = yellow 0.32, l2 = yellow, l3 = orange, l4 = red.
    - Strength: l1-l3 balance ramp, l4 = yellow with gold glow drop-shadow blur.
  - Surface-colored 2.5-width hairlines with `StrokeJoin.round` separating parts.
  - Label-colored 7.0-width outline on selected muscle.
  - `BodyMapFit` aspect-ratio preserving transform and inverse coordinate mapping.
  - Reverse paint order hit-testing for muscle taps (`view.muscles.reversed`).
- **BodyMap Widget & BodyMapLegend**:
  - `BodyMap`: Statefully loads geometry from cache, displays 200px placeholder while loading, renders front and back views side by side in a Row with 6px gap, clamped to max-height 340px or 46vh.
  - Supports `onMuscle` callback and provides accessibility semantics with muscle display names from `muscles.muscleName`.
  - `BodyMapLegend`: Right-aligned 10x10 legend box indicators for balance ('Less' -> 'More'), fatigue ('Fatigued', 'Recovering', 'Ready'), and strength ('1 full' -> '{strengthFloor} floor').

---

## Changes Implemented

### 1. Palette Extension
- `lib/core/theme/app_palette.dart`:
  - Added `final Color label;` field.
  - Mapped `--label` in `cssVar`.
  - Defined white in dark mode and black in light mode.

### 2. Geometry Cache
- `lib/core/body_map/body_geometry_cache.dart`:
  - `BodyPartKind` enum (`inert`, `muscle`).
  - `BodyPart`, `BodyViewGeometry`, `BodyGeometry`.
  - `BodyGeometryCache` singleton with `load()` and `peek()`.

### 3. Painter & Widget
- `lib/core/body_map/body_map_painter.dart`:
  - `BodyMapVariant`, `BodyMapColors`, `BodyMapFit`, `BodyMapPainter`.
  - Full path rendering, stroke decoration, gold glow, and hit testing.
- `lib/core/body_map/body_map.dart`:
  - `BodyMap` widget and `BodyMapLegend`.
  - Exports painter and cache from barrel.

---

## Verification Results
- `flutter analyze`: 0 issues found.
- `bash tool/js04_audit.sh`: PASS (0 forbidden imports or math patterns).
- Strict pattern checks passed:
  - Exact color mix parameters (0.11, 0.18, 0.32, 0.56, 0.78, 0.30, 0.55).
  - Exact stroke widths (2.5 and 7.0) with `StrokeJoin.round`.
  - Reverse order hit testing (`reversed`).
  - Placeholder (200px) and max-height clamps (340px, 0.46).
  - No domain level math written in Dart.
