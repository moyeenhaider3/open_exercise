#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Generates reproducible, vitest-cross-checked parity fixtures for Phase 2 (JS-03).
# Verifies timezone-determinism under UTC, Asia/Kolkata, and America/Los_Angeles.
#
# Usage:
#   tool/gen_js_fixtures.sh
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VENDORED_DIR="third_party/opengym/lib"
MANIFEST_FILE="$VENDORED_DIR/MANIFEST.sha256"
OUT_DIR="tool/fixtures/js-parity"
DART_FILE="tool/parity/parity_fixtures_data.dart"

# Step 1: Verify source manifest integrity
if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "gen_js_fixtures.sh: manifest missing at $MANIFEST_FILE" >&2
  exit 1
fi

echo "Verifying integrity of vendored sources in $VENDORED_DIR ..."
(
  cd "$VENDORED_DIR"
  shasum -a 256 -c MANIFEST.sha256
)

# Step 2: Generate canonical fixtures under TZ=UTC
echo "Generating parity fixtures under TZ=UTC ..."
mkdir -p "$OUT_DIR"
TZ=UTC node tool/js/gen-fixtures.mjs --out "$OUT_DIR" --dart "$DART_FILE"

# Step 3: Timezone determinism check against Asia/Kolkata and America/Los_Angeles
TMP_KOLKATA="$(mktemp -d "${TMPDIR:-/tmp}/parity_kolkata.XXXXXX")"
TMP_LA="$(mktemp -d "${TMPDIR:-/tmp}/parity_la.XXXXXX")"
trap 'rm -rf "$TMP_KOLKATA" "$TMP_LA"' EXIT

echo "Verifying timezone determinism under TZ=Asia/Kolkata ..."
TZ=Asia/Kolkata node tool/js/gen-fixtures.mjs --out "$TMP_KOLKATA"
diff -r "$OUT_DIR" "$TMP_KOLKATA"
echo "TZ=Asia/Kolkata match confirmed."

echo "Verifying timezone determinism under TZ=America/Los_Angeles ..."
TZ=America/Los_Angeles node tool/js/gen-fixtures.mjs --out "$TMP_LA"
diff -r "$OUT_DIR" "$TMP_LA"
echo "TZ=America/Los_Angeles match confirmed."

# Step 4: Format generated Dart embed file
echo "Formatting $DART_FILE ..."
dart format "$DART_FILE"

echo "Parity fixtures generated and verified successfully!"
