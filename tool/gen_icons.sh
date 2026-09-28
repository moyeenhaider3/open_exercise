#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Generates lib/core/ui_kit/icons/app_icon_data.g.dart from openGym's Icon.jsx.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE_BIN="${NODE_BIN:-node}"

cd "$PROJECT_ROOT/tool/js"
"$NODE_BIN" gen-icons.mjs
