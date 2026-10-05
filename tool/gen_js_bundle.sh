#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Reproducible openGym lib bundling for Phase 2 (JS-01).
# Vendors openGym frontend modules into third_party/opengym/lib/ and bundles them
# into assets/js/opengym-lib.bundle.js using pinned esbuild (0.28.2).
#
# Usage:
#   tool/gen_js_bundle.sh         # rebuild bundle from committed vendored sources
#   tool/gen_js_bundle.sh --sync  # sync from ../openGym/frontend/src/lib/ first, then rebuild
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SOURCE_LIB_DIR="../openGym/frontend/src/lib"
SOURCE_PKG="../openGym/frontend/package.json"
VENDORED_DIR="third_party/opengym/lib"
MANIFEST_FILE="$VENDORED_DIR/MANIFEST.sha256"
VERSION_FILE="$VENDORED_DIR/VERSION"
ENTRY_FILE="tool/js/entry.js"
OUT_BUNDLE="assets/js/opengym-lib.bundle.js"
ESBUILD_BIN="tool/js/node_modules/.bin/esbuild"
EXPECTED_ESBUILD_VERSION="0.28.2"

FILES=(
  "backfill.js"
  "bar.js"
  "effort.js"
  "exercise-history.js"
  "exercise-muscle-batch-1.js"
  "exercise-muscle-batch-1.json"
  "exercise-muscle-batch-2.js"
  "exercise-muscle-batch-2.json"
  "exercise-muscle-olympic.json"
  "exercises-data.js"
  "exercises.js"
  "finish-workout.js"
  "format.js"
  "history.js"
  "i18n-core.js"
  "muscles.js"
  "onerm.js"
  "progression-copy.js"
  "progression.js"
  "recovery.js"
  "recovery-view.js"
  "rep-range.js"
  "session-merge.js"
  "session-start.js"
  "starter.js"
  "strength-exercises.js"
  "supersetFlow.js"
  "units.js"
  "workout-model.js"
)

# Step 1: Optional --sync from ../openGym
if [[ "${1:-}" == "--sync" ]]; then
  if [[ ! -d "$SOURCE_LIB_DIR" || ! -f "$SOURCE_PKG" ]]; then
    echo "gen_js_bundle.sh --sync: openGym source not found at $SOURCE_LIB_DIR (expects sibling ../openGym)" >&2
    exit 1
  fi
  echo "Syncing openGym lib files from $SOURCE_LIB_DIR ..."
  mkdir -p "$VENDORED_DIR"
  for f in "${FILES[@]}"; do
    if [[ ! -f "$SOURCE_LIB_DIR/$f" ]]; then
      echo "gen_js_bundle.sh --sync: missing expected file $SOURCE_LIB_DIR/$f" >&2
      exit 1
    fi
    cp "$SOURCE_LIB_DIR/$f" "$VENDORED_DIR/$f"
  done

  # Extract version from package.json
  node -e "
    const pkg = JSON.parse(require('fs').readFileSync('$SOURCE_PKG', 'utf8'));
    require('fs').writeFileSync('$VERSION_FILE', pkg.version + '\n', 'utf8');
    console.log('Synced openGym frontend version:', pkg.version);
  "

  # Regenerate MANIFEST.sha256 sorted by filename
  (
    cd "$VENDORED_DIR"
    ls -1 *.js *.json | sort | xargs shasum -a 256 > MANIFEST.sha256
  )
fi

# Step 2: Always verify source integrity against MANIFEST.sha256
if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "gen_js_bundle.sh: manifest missing at $MANIFEST_FILE. Run with --sync first." >&2
  exit 1
fi

echo "Verifying integrity of vendored sources in $VENDORED_DIR ..."
(
  cd "$VENDORED_DIR"
  shasum -a 256 -c MANIFEST.sha256
)

# Step 3: Ensure pinned esbuild is present and exact version
if [[ ! -x "$ESBUILD_BIN" ]]; then
  echo "esbuild not found under tool/js. Running npm ci --prefix tool/js ..."
  npm ci --prefix tool/js
fi

ESBUILD_VERSION="$("$ESBUILD_BIN" --version)"
if [[ "$ESBUILD_VERSION" != "$EXPECTED_ESBUILD_VERSION" ]]; then
  echo "gen_js_bundle.sh: esbuild version mismatch! Expected $EXPECTED_ESBUILD_VERSION, found $ESBUILD_VERSION" >&2
  exit 1
fi

# Step 4: Compute provenance metadata
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "gen_js_bundle.sh: VERSION file missing at $VERSION_FILE" >&2
  exit 1
fi
OPENGYM_VERSION="$(tr -d '\r\n' < "$VERSION_FILE")"
SOURCE_SHA="$(shasum -a 256 "$MANIFEST_FILE" | cut -d' ' -f1)"

echo "Bundling openGym v$OPENGYM_VERSION (source manifest SHA: $SOURCE_SHA) ..."

# Step 5 & 6: esbuild bundling
mkdir -p "$(dirname "$OUT_BUNDLE")"
METAFILE_TMP="$(mktemp "${TMPDIR:-/tmp}/opengym_meta.XXXXXX.json")"
trap 'rm -f "$METAFILE_TMP"' EXIT

BANNER="/* SPDX-License-Identifier: AGPL-3.0-or-later
 * Bundled from openGym frontend v${OPENGYM_VERSION} (sourceSha256: ${SOURCE_SHA})
 * bundled by tool/gen_js_bundle.sh, esbuild ${EXPECTED_ESBUILD_VERSION}
 * See NOTICE.md and third_party/opengym/README.md.
 */
var __openGymLibMeta = {\"openGymVersion\":\"${OPENGYM_VERSION}\",\"sourceSha256\":\"${SOURCE_SHA}\",\"esbuild\":\"${EXPECTED_ESBUILD_VERSION}\",\"target\":\"es2019\"};
if (typeof String.prototype.replaceAll !== 'function') {
  String.prototype.replaceAll = function(searchValue, replaceValue) {
    if (typeof searchValue !== 'string') {
      throw new TypeError('searchValue must be a string in this polyfill');
    }
    return this.split(searchValue).join(replaceValue);
  };
}
if (typeof Array.prototype.at !== 'function') {
  Array.prototype.at = function(n) {
    n = Math.trunc(n) || 0;
    if (n < 0) n += this.length;
    if (n < 0 || n >= this.length) return undefined;
    return this[n];
  };
}"

# We pass --log-override:empty-import-meta=silent because exercises.js has
# `const ENV = import.meta.env || {}`. In an IIFE build, esbuild replaces
# import.meta with an empty object {}, which makes ENV = {}, exactly matching
# plain Node behavior where import.meta.env is undefined.
"$ESBUILD_BIN" "$ENTRY_FILE" \
  --bundle \
  --format=iife \
  --global-name=OpenGymLib \
  --target=es2019 \
  --charset=utf8 \
  --legal-comments=none \
  --log-override:empty-import-meta=silent \
  --banner:js="$BANNER" \
  --metafile="$METAFILE_TMP" \
  --outfile="$OUT_BUNDLE"

# Step 7: Verify inputs from metafile
node -e "
  const fs = require('fs');
  const meta = JSON.parse(fs.readFileSync('$METAFILE_TMP', 'utf8'));
  const allowed = new Set([
    'tool/js/entry.js',
    'tool/js/shims/finish-workout-shim.js',
    'tool/js/shims/view-aggregates-shim.js',
    'tool/js/shims/muscle-view-shim.js',
    'tool/js/shims/reminder-shim.js',
    ...[
      'backfill.js',
      'bar.js', 'effort.js', 'exercise-history.js',
      'exercise-muscle-batch-1.js', 'exercise-muscle-batch-1.json',
      'exercise-muscle-batch-2.js', 'exercise-muscle-batch-2.json',
      'exercise-muscle-olympic.json', 'exercises-data.js', 'exercises.js',
      'finish-workout.js', 'format.js', 'history.js', 'i18n-core.js', 'muscles.js', 'onerm.js',
      'progression-copy.js', 'progression.js', 'recovery.js', 'recovery-view.js', 'rep-range.js', 'session-merge.js',
      'session-start.js', 'starter.js', 'strength-exercises.js', 'supersetFlow.js', 'units.js', 'workout-model.js'
    ].map(f => 'third_party/opengym/lib/' + f)
  ]);
  const inputs = Object.keys(meta.inputs);
  for (const input of inputs) {
    if (!allowed.has(input)) {
      console.error('Unexpected bundle input:', input);
      process.exit(1);
    }
  }
  console.log('Metafile input audit PASSED (' + inputs.length + ' inputs).');
"

BUNDLE_SHA="$(shasum -a 256 "$OUT_BUNDLE" | cut -d' ' -f1)"
BUNDLE_SIZE="$(wc -c < "$OUT_BUNDLE" | tr -d ' ')"

echo "Bundle created at $OUT_BUNDLE"
echo "Size: $BUNDLE_SIZE bytes"
echo "SHA-256: $BUNDLE_SHA"
