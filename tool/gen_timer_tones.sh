#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Generates audio tones (WAV) matching openGym sound.js beep() envelope.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE_BIN="${NODE_BIN:-node}"

cd "$PROJECT_ROOT/tool/js"
"$NODE_BIN" gen-timer-tones.mjs
