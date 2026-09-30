# Plan 04-03 Summary: xml Dependency Installation & Body-Map SVG Asset Generation

## Executive Summary
Plan `04-03` installed and attributed the user-mandated `xml` package and generated four reproducible, attributed SVG XML geometry assets from openGym's `body-paths.js`:
- **Package Legitimacy Gate**: Verified `xml` 7.1.0 on pub.dev (publisher `lukas-renggli.ch`, repo `https://github.com/renggli/dart-xml`, MIT license, 160/160 score) and dry-run resolution with user approval before install.
- **Dependency & Attribution**: Installed `xml: ^7.1.0` (which pulled in transitive `petitparser: 7.1.0`). Added MIT license attribution for `xml` / `petitparser` and copied the full MuscleMap MIT license block from openGym's `NOTICE.md` into `NOTICE.md` under a new "Body-map geometry" section.
- **Generator & Wrapper**: Created `tool/js/gen-body-paths.mjs` and wrapper `tool/gen_body_paths.sh` to extract geometry from `../openGym/frontend/src/lib/body-paths.js` via `esbuild.transformSync`.
- **Generated Assets**: Produced 4 deterministic SVG XML files (`male-front.svg`, `male-back.svg`, `female-front.svg`, `female-back.svg`) matching exact viewBoxes, path counts (97, 70, 100, 66), and strict openGym paint order (all `INERT` paths followed by `MUSCLES` paths).
- **Pubspec Registration**: Added `- assets/body/` to `flutter: assets:` in `pubspec.yaml`.

---

## Changes Implemented

### 1. Dependencies & Attribution
- `pubspec.yaml`:
  - Added `xml: ^7.1.0` under `dependencies:`.
  - Added `- assets/body/` under `flutter: assets:`.
- `pubspec.lock`:
  - Locked `xml 7.1.0` and `petitparser 7.1.0`.
- `NOTICE.md`:
  - Updated "This project's own dependencies" section to cite `xml` and `petitparser` under MIT.
  - Added "Body-map geometry" section with attribution to Melih Colpan and the full MuscleMap MIT license text.

### 2. Generator Tooling
- `tool/js/gen-body-paths.mjs`:
  - Loads and hashes `../openGym/frontend/src/lib/body-paths.js`.
  - Imports `INERT` and `MUSCLES` from vendored `third_party/opengym/lib/muscles.js`.
  - Emits XML declaration, AGPL/attribution comments, `<svg>` with source viewBox, and one `<path>` per line with `data-part` and `data-kind`.
  - Strictly preserves openGym paint order (`INERT` parts in `INERT` order, then `MUSCLES` in `MUSCLES` order).
- `tool/gen_body_paths.sh`:
  - Shell runner ensuring `assets/body` directory exists and executing `gen-body-paths.mjs`.

### 3. Generated Assets
- `assets/body/male-front.svg`: 97 paths (31 inert, 66 muscle), `viewBox="0 95 727 1280"`.
- `assets/body/male-back.svg`: 70 paths (20 inert, 50 muscle), `viewBox="718 95 727 1280"`.
- `assets/body/female-front.svg`: 100 paths (34 inert, 66 muscle), `viewBox="0 0 650 1450"`.
- `assets/body/female-back.svg`: 66 paths (18 inert, 48 muscle), `viewBox="823 0 650 1450"`.

---

## Verification Results
- All 4 SVGs parsed as valid XML without warnings or errors.
- Double-run SHA-256 diff test verified 100% byte-for-byte reproducibility.
- Paint order verification confirmed all `data-kind="inert"` precede `data-kind="muscle"` in every file.
- `flutter analyze`: 0 issues found.
