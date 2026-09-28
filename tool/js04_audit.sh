#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# tool/js04_audit.sh - Audit Dart source files to enforce architectural rule JS-04.
#
# JS-04 specifies that no mathematical domain logic (1RM calculations, progression formulas,
# plate splits, fatigue decays, or phase/type resolution) may be hand-written in Dart; all
# calculations must delegate to the bundled openGym JavaScript library.
#
# Rule JS-04 is enforced by review; this script constitutes the mechanical verification part.
#
# Usage:
#   bash tool/js04_audit.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAILURES=0

fail() {
  echo "FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

# Find all relevant Dart files under lib/, excluding generated files
find_dart_files() {
  local dir="${1:-lib}"
  if [ -d "$dir" ]; then
    find "$dir" -type f -name "*.dart" ! -path "*/core/api/generated/*" ! -name "*.g.dart"
  fi
}

echo "=== Running JS-04 Architectural Audit ==="

# (a) Disallowed phase/type identifiers from Phase 1 CR-02 stopgap
A_PATTERN='_normalizedPhase|resolvedPhase|resolvedPhaseOr|resolvedType'
A_HITS=$(find_dart_files "lib" | xargs grep -nE "$A_PATTERN" 2>/dev/null || true)
if [ -n "$A_HITS" ]; then
  fail "Disallowed phase/type identifiers found (must delegate to workout-model.js):"
  echo "$A_HITS"
fi

# (b) dart:math imports under forbidden directories (models, js bridge, blocs)
B_HITS=""
for subdir in "lib/core/models" "lib/core/js"; do
  if [ -d "$subdir" ]; then
    HITS=$(find_dart_files "$subdir" | xargs grep -nE "import\s+['\"]dart:math['\"]" 2>/dev/null || true)
    if [ -n "$HITS" ]; then
      B_HITS="${B_HITS}${HITS}"$'\n'
    fi
  fi
done
# Check lib/features/*/bloc
if [ -d "lib/features" ]; then
  BLOC_HITS=$(find lib/features -type d -name "bloc" 2>/dev/null | while read -r bdir; do
    find_dart_files "$bdir" | xargs grep -nE "import\s+['\"]dart:math['\"]" 2>/dev/null || true
  done)
  if [ -n "$BLOC_HITS" ]; then
    B_HITS="${B_HITS}${BLOC_HITS}"$'\n'
  fi
fi
if [ -n "$(echo -n "$B_HITS" | tr -d '[:space:]')" ]; then
  fail "Disallowed import 'dart:math' found in domain/model/bloc layers:"
  echo "$B_HITS"
fi

# (c) Formula and constant fingerprints from openGym math
C_PATTERN='/ 30\b|36 / \(37|pow\(|0\.45359237|129600000|1209600000|2419200000|\* 0\.9\b'
C_HITS=$(find_dart_files "lib" | xargs grep -nE "$C_PATTERN" 2>/dev/null || true)
if [ -n "$C_HITS" ]; then
  fail "Math formula/constant fingerprint found in Dart files:"
  echo "$C_HITS"
fi

# (d) Function/method declarations of domain algorithms outside lib/core/js/modules/
D_PATTERN='(double|num|int|String)\??\s+(epley|brzycki|lombardi|plateSplit|deloadTo|halfLifeDecay)\w*\s*\('
D_HITS=$(find_dart_files "lib" | grep -v "lib/core/js/modules/" | xargs grep -nE "$D_PATTERN" 2>/dev/null || true)
if [ -n "$D_HITS" ]; then
  fail "Domain algorithm declarations found outside lib/core/js/modules/:"
  echo "$D_HITS"
fi

if [ "$FAILURES" -gt 0 ]; then
  echo ""
  echo "JS-04 audit: FAILED ($FAILURES violation(s) found)"
  exit 1
fi

echo "JS-04 audit: PASS"
exit 0
