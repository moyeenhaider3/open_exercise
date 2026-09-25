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
