# Vendored openGym API spec

`openapi.yaml` in this directory is a byte-for-byte copy of `../openGym/api/openapi.yaml`
(OpenAPI 3.1.0), vendored so `tool/gen_api.sh` has a stable, reviewable input that does not
require a checkout of the sibling `openGym` repo to build.

## Provenance

- **Source path:** `../openGym/api/openapi.yaml` (sibling checkout, relative to this repo's root)
- **Source control:** `../openGym` is **not a git repository** on this machine (`git -C ../openGym
  rev-parse HEAD` fails with "not a git repository"), so no commit hash can be recorded. Provenance
  is instead pinned by content hash and source mtime, captured at vendor time (2026-09-25):
  - SHA-256: `81df9bbe4108b7d7486eb8c81042dcc67ba2aa9f1d23e3423197cabef7ed749c`
  - Source file mtime: `Sep 21 00:56:06 2026`
- **License:** AGPL-3.0-or-later, inherited from openGym (see the repo root `LICENSE` and
  `NOTICE.md`). This spec is an unmodified copy of openGym's own API contract, not new IP.

## Refreshing

Run `tool/gen_api.sh --sync` to refresh: it re-copies this file from `../openGym/api/openapi.yaml`
and then regenerates `lib/core/api/generated/`. Do not hand-edit `openapi.yaml` in this directory —
always sync from the source and regenerate.

## Vendored openGym lib modules (Phase 2, JS-01)

The files in `third_party/opengym/lib/` are exact copies of the openGym frontend domain modules needed by the Flutter QuickJS bridge.

### Provenance

- **Source path:** `../openGym/frontend/src/lib/` (sibling checkout, relative to this repo's root)
- **openGym frontend version:** `1.3.8` (from `../openGym/frontend/package.json`)
- **Vendor date:** 2026-09-25
- **Source control:** `../openGym` is **not a git repository** on this machine (`git -C ../openGym rev-parse HEAD` fails with "not a git repository"), so no commit hash can be recorded. Provenance and integrity are tracked via `third_party/opengym/lib/MANIFEST.sha256` (19 source files) and `VERSION`.
- **License:** AGPL-3.0-or-later, inherited from openGym (see `LICENSE` and `NOTICE.md`).

### Vendored Files (19 files)

**Bridged entry modules (8 namespaces):**
- `onerm.js`: 1RM estimation formulas (Brzycki, Epley, Lander, etc.)
- `progression.js`: Progression recommendations and rep target logic
- `bar.js`: Plate calculation and barbell loading math
- `workout-model.js`: Workout structure, set types, and volume computation
- `recovery.js`: Recovery metrics and muscle fatigue scoring
- `history.js`: Exercise and workout history analysis
- `session-start.js`: Workout session initialization logic
- `session-merge.js`: Local and remote session conflict resolution

**Transitive dependencies (11 files):**
- `exercises.js`: Exercise definitions and lookups (imports exercises-data.js, exercise-muscle-batch-1.js, i18n-core.js)
- `exercises-data.js`: Exercise database (~888 KB)
- `exercise-muscle-batch-1.js`: Muscle mapping part 1
- `exercise-muscle-batch-1.json`: Muscle mapping JSON data
- `exercise-muscle-olympic.json`: Olympic movement muscle mapping JSON data
- `exercise-muscle-batch-2.js`: Muscle mapping part 2
- `exercise-muscle-batch-2.json`: Muscle mapping JSON data part 2
- `muscles.js`: Muscle groups and body part relationships
- `format.js`: Number and unit formatting helpers
- `i18n-core.js`: Core string formatting and i18n tokens
- `rep-range.js`: Rep range parsing and validation utilities

### Refreshing

Never hand-edit files in `third_party/opengym/lib/`. Refresh with:
```bash
tool/gen_js_bundle.sh --sync
```

