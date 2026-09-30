#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Generates assets/body/*.svg from openGym's body-paths.js.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE_BIN="${NODE_BIN:-node}"

mkdir -p "$PROJECT_ROOT/assets/body"

cd "$PROJECT_ROOT/tool/js"
"$NODE_BIN" gen-body-paths.mjs
