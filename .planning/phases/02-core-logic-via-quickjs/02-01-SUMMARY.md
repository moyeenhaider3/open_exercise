# Phase 2 Plan 01 Summary: Vendor openGym Lib & Reproducible esbuild Bundle

## Outcome
Successfully vendored the 19 required openGym lib modules with SHA-256 integrity verification, isolated pinned esbuild (0.28.2) tooling under `tool/js/`, created `tool/js/entry.js` and `tool/gen_js_bundle.sh`, and generated the deterministic IIFE bundle at `assets/js/opengym-lib.bundle.js`.

## Key Metrics
- **openGym version:** `1.3.8` (from `../openGym/frontend/package.json`)
- **Vendored source files:** 19 files (8 bridged modules + 11 transitive dependencies)
- **Source manifest SHA-256 (`sourceSha256`):** `2190ad561541aa09fc6745b92f1e0ff78063a58ad544c3d3c5eb0c36acc21dad`
- **Bundle output path:** `assets/js/opengym-lib.bundle.js`
- **Bundle SHA-256:** `f454c4a2908ceea9d73126fc238efbc017fa2b63ca20a79f2c05a45c4ce7f920`
- **Bundle size:** `1,054,840` bytes (~1.0 MB)
- **esbuild warnings:** Standard output indicated `assets/js/opengym-lib.bundle.js 1.0mb ⚠️` (notice for files > 1 MB), no fatal errors or syntax warnings. `--log-override:empty-import-meta=silent` cleanly handled `import.meta.env`.
- **Determinism:** Two consecutive `tool/gen_js_bundle.sh` runs produced identical bundle SHA-256 hashes.
- **Node evaluation:** Verified in bare `node:vm` context with no module loader; `OpenGymLib` exposes 8 namespaces (`onerm`, `progression`, `bar`, `workoutModel`, `recovery`, `history`, `sessionStart`, `sessionMerge`), `estimate1RM(100,5) === 116.7`, `plateSplit(100,20) === 40`, and `__openGymLibMeta.openGymVersion === "1.3.8"`.

## Artifacts Created & Modified
- `third_party/opengym/lib/*.js`, `*.json`: 19 vendored source files
- `third_party/opengym/lib/MANIFEST.sha256`: SHA-256 manifest of vendored files
- `third_party/opengym/lib/VERSION`: `1.3.8`
- `third_party/opengym/README.md`: Documented provenance, file list, and refresh command
- `NOTICE.md`: Updated third-party attribution for vendored modules and bundle
- `tool/js/package.json`, `tool/js/package-lock.json`: Isolated npm tooling with exact-pinned `esbuild: 0.28.2`
- `tool/js/entry.js`: IIFE entry point exporting 8 namespaces
- `tool/gen_js_bundle.sh`: Executable build/sync script with integrity and metafile checks
- `assets/js/opengym-lib.bundle.js`: Committed IIFE bundle asset
- `.gitignore`: Added `tool/js/node_modules/`
