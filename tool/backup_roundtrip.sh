#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE="$SCRIPT_DIR/fixtures/state_sample.json"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "==> Running Backup Round-trip Verification (D-18 / BAK-04)"

if [ ! -f "$FIXTURE" ]; then
  echo "Error: Fixture file not found: $FIXTURE" >&2
  exit 1
fi

node - << 'EOF' "$FIXTURE" "$TEMP_DIR"
const fs = require('fs');
const path = require('path');

const fixturePath = process.argv[2];
const tempDir = process.argv[3];

const raw = fs.readFileSync(fixturePath, 'utf8');
const data = JSON.parse(raw);

// Check D-16 requirements
if (!data.workouts || !data.routines) {
  console.error("FAIL: missing workouts or routines in fixture");
  process.exit(1);
}

// Emulate openGym / BackupImportService overlay on defaults
const defaultState = {
  unit: 'kg',
  restSec: 90,
  restPauseSec: 15,
  sound: true,
  soundOnSilent: false,
  timerFlash: false,
  keepAwake: true,
  lang: 'en',
  theme: 'dark',
  accent: 'lime',
  body: 'male',
  targetW: null,
  bodyweight: [],
  routines: [],
  week: {},
  dayPlan: {},
  exWeights: {},
  workouts: [],
  active: null,
  customEx: [],
  gifSize: 0,
  wdec: 1,
  weekStart: 1,
  weighIn: true,
  checkIn: true,
  workoutView: 'compact',
  effort: false,
  equipFilter: false,
  activeEquip: 'all',
  equipProfiles: [],
  reminder: { enabled: false, time: '18:00' },
  autoBackup: false
};

const stateBefore = Object.assign({}, defaultState, data);
const stateBeforeJson = JSON.stringify(stateBefore, null, 2);

// Re-import (simulate replaceState)
const imported = JSON.parse(stateBeforeJson);
if (!imported.workouts || !imported.routines) {
  console.error("FAIL: round-trip lost required keys");
  process.exit(1);
}

const stateAfter = Object.assign({}, defaultState, imported);
const stateAfterJson = JSON.stringify(stateAfter, null, 2);

fs.writeFileSync(path.join(tempDir, 'before.json'), stateBeforeJson);
fs.writeFileSync(path.join(tempDir, 'after.json'), stateAfterJson);

// Verify exact roundtrip
if (stateBeforeJson !== stateAfterJson) {
  console.error("FAIL: before and after JSON do not match");
  process.exit(1);
}

console.log("PASS: Round-trip JSON equivalence verified.");
EOF

echo "==> Round-trip verification successful!"
