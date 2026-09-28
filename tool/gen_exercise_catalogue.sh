#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Generates assets/data/exercise_catalogue.json from openGym's vendored exercise library.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE_BIN="${NODE_BIN:-node}"

cd "$PROJECT_ROOT/tool/js"
"$NODE_BIN" gen-catalogue.mjs
