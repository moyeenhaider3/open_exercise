// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Synthesizes tool/fixtures/state_sample.json: a deterministic, fully synthetic FND-03/FND-04
// round-trip fixture built from openGym's own demo-data generator
// (../openGym/frontend/src/lib/demoSeed.js -- buildDemoState) plus hand-authored edge cases
// (dropsets, rest-pause clusters, warm-up phase, per-side sets, supersets, explicit nulls,
// unknown keys and a malformed value). No real user export is used anywhere in this script.
//
// FIXTURE PATH DEVIATION (orchestrator decision, 01-03 plan, no-tests rule): this file writes to
// tool/fixtures/state_sample.json instead of test/fixtures/state_sample.json, because writes
// under test/ are blocked by the project's no-tests PreToolUse hook. Plans 01-04/01-06 must read
// the fixture from this path. See 01-03-SUMMARY.md "Deviations from Plan".
//
// Determinism: buildDemoState() and format.js's uid() read the wall clock (`new Date()`,
// `Date.now()`) and Math.random(). Both are pinned below, BEFORE the dynamic import of
// demoSeed.js, so running this script twice produces a byte-identical file
// (verified by: `node tool/fixtures/gen_state_fixture.mjs && git diff --quiet
// tool/fixtures/state_sample.json`).

import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// --- pin the clock: every `new Date()` / `Date.now()` call sees 2026-09-25T12:00:00Z ----------
const FIXED_ISO = '2026-09-25T12:00:00Z'
const FIXED_MS = Date.parse(FIXED_ISO)
const OriginalDate = Date
class PinnedDate extends OriginalDate {
  constructor(...args) {
    if (args.length === 0) super(FIXED_MS)
    else super(...args)
  }
  static now() { return FIXED_MS }
}
globalThis.Date = PinnedDate

// --- pin Math.random with a seeded mulberry32 PRNG (seed 20260925) -----------------------------
// Mirrors the technique demoSeed.js itself uses for its own internal `rng()` helper, so the
// "life happens" missed-session roll and format.js's `uid()` (Date.now() + Math.random()) are
// both reproducible across runs.
function mulberry32(seed) {
  let a = seed >>> 0
  return function () {
    a = (a + 0x6d2b79f5) >>> 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
Math.random = mulberry32(20260925)

// --- DEF, copied literally from ../openGym/frontend/src/store/useStore.js lines 23-85 ---------
// (useStore.js itself is not imported: it pulls in zustand, which is not installed for this
// plain-node script; WC_DEFAULT is imported for real from workout-controls.js below, matching
// useStore.js's own `wc: { ...WC_DEFAULT }`.)
const DEF = {
  unit: 'kg', restSec: 90, restPauseSec: 15, sound: true, soundOnSilent: false, timerFlash: false, keepAwake: true, lang: 'en',
  theme: 'dark', accent: 'lime', body: 'male', targetW: null,
  bodyweight: [], routines: [], week: {}, dayPlan: {},
  exWeights: {}, workouts: [], active: null, customEx: [], gifSize: 'full',
  workoutView: 'cards',
  wc: null, // filled below with { ...WC_DEFAULT }
  reminder: { on: false, time: '08:00', tz: null }, effort: null, autoBackup: false,
  equipProfiles: [], activeEquipId: null, equipFilterOn: false,
  exNotes: {},
  favEx: [],
  weekStart: 1,
  wdec: 1,
  barWeights: {},
  gymCards: [],
  lastGymCardId: null,
  checkIn: true,
  weighIn: true,
}

async function main() {
  const { buildDemoState } = await import('../../../openGym/frontend/src/lib/demoSeed.js')
  const { WC_DEFAULT } = await import('../../../openGym/frontend/src/lib/workout-controls.js')
  DEF.wc = { ...WC_DEFAULT }

  const state = Object.assign(structuredClone(DEF), buildDemoState())

  if (!Array.isArray(state.workouts) || state.workouts.length < 6) {
    throw new Error(`buildDemoState() produced only ${state.workouts?.length ?? 0} workouts, need >= 6`)
  }

  // ---- hand augmentation: fixed literal ids/timestamps only, no further rng calls ------------
  const last3 = state.workouts.slice(-3)
  const [wDrop, wRestPause, wWarm] = last3

  // wDrop: turn one set into a dropset; mark the workout and its entry with future-key probes.
  {
    const entry = wDrop.entries[0]
    entry.__futureEntryKey = 7
    const sets = entry.sets
    sets[sets.length - 1] = {
      w: 60, r: 8, done: true, type: 'dropset',
      drops: [{ w: 50, r: 6 }, { w: 40, r: 5 }],
      __futureSetKey: { a: null },
    }
    wDrop.__futureWorkoutKey = 'keep-me'
  }

  // wRestPause: turn one set into a rest-pause set; add a malformed (string) weight elsewhere.
  {
    const entry = wRestPause.entries[0]
    const sets = entry.sets
    sets[sets.length - 1] = {
      w: 40, r: 15, done: true, type: 'restpause',
      clusters: [{ r: 4, restSec: 15 }, { r: 3, restSec: 15 }],
    }
    const otherEntry = wRestPause.entries[1] ?? wRestPause.entries[0]
    otherEntry.sets[0] = { ...otherEntry.sets[0], w: '82.5' }
  }

  // wWarm: prepend a warm-up + legacy warm-up, add a per-side entry, mark a superset, add a
  // null-valued known field.
  {
    const firstEntry = wWarm.entries[0]
    firstEntry.sets.unshift(
      { w: 20, r: 10, done: true, phase: 'warmup' },
      { w: 20, r: 8, done: true, warmup: true },
    )
    if (wWarm.entries[1]) {
      const rirSet = wWarm.entries[1].sets[0]
      if (rirSet) rirSet.rir = null
    }
    if (wWarm.entries.length >= 2) {
      wWarm.entries[0].sg = 'ss_fixture_1'
      wWarm.entries[1].sg = 'ss_fixture_1'
    }
    wWarm.entries.push({
      id: 'db_curl_fixture',
      sets: [
        { w: 12, r: 19, done: true, sides: { L: { w: 12, r: 10, done: true }, R: { w: 12, r: 9, done: true } } },
        {
          w: 12, r: 17, done: true,
          sides: {
            L: { w: 12, r: 8, done: true, type: 'dropset', drops: [{ w: 8, r: 6 }] },
            R: { w: 12, r: 9, done: true },
          },
        },
      ],
    })
  }

  // Top-level passthrough probe.
  state.__futureTopLevel = { nested: [1, 2, { deep: true }] }

  // One routine gets an unknown key.
  if (state.routines[0]) state.routines[0].__futureRoutineKey = true

  // Fixed synthetic top-level settings/collections.
  state._ts = 1790000000000
  state._rev = 42
  state.targetW = 80
  state.effort = 'rir'
  state.reminder = { on: true, time: '07:30', tz: 'Europe/Zurich' }
  state.theme = 'dark'
  state.accent = 'sky'
  state.weekStart = 1
  state.wdec = 2
  state.equipFilterOn = true
  state.activeEquipId = 'eq_home'
  state.equipProfiles = [
    { id: 'eq_home', name: 'Home', equipment: ['dumbbell', 'body weight'] },
    { id: 'eq_gym', name: 'Gym', equipment: ['barbell', 'cable', 'machine'] },
  ]
  state.gymCards = [{ id: 'gc1', label: 'City Gym', value: '1234567890128', fmt: 'ean13' }]
  state.lastGymCardId = 'gc1'
  state.customEx = [{ id: 'custom_landmine', name: 'Landmine Press', muscles: ['shoulders'], eq: 'barbell' }]

  const demoExIdA = state.routines[0]?.ex?.[0]?.id ?? '0025'
  const demoExIdB = state.routines[1]?.ex?.[0]?.id ?? '2330'
  const demoExIdC = state.routines[0]?.ex?.[1]?.id ?? demoExIdA
  state.favEx = [demoExIdA, demoExIdB]
  state.barWeights = { [demoExIdA]: 15 }
  state.exNotes = { [demoExIdC]: 'seat 4, pin 7' }
  state.dayPlan = { ...state.dayPlan, '2026-09-20': 'rest' }
  // state.week is already { 1: push.id, 3: pull.id, 5: legs.id } from buildDemoState(), which
  // JSON.stringify serializes with string keys "1"/"3"/"5" -- matches the plan's requirement.

  const pushRoutineId = state.routines[0]?.id ?? null
  const lastWorkoutDate = state.workouts[state.workouts.length - 1]?.d ?? '2026-09-25'
  state.active = {
    id: 'active_fixture',
    d: lastWorkoutDate,
    start: 1790000100000,
    routineIds: pushRoutineId ? [pushRoutineId] : [],
    name: 'Push',
    bw: null,
    cur: 1,
    view: 'list',
    entries: [
      {
        id: demoExIdA,
        sets: [
          { w: 60, r: 8, done: true },
          { w: 60, r: 8, done: false },
        ],
      },
    ],
  }

  const outPath = path.join(__dirname, 'state_sample.json')
  writeFileSync(outPath, JSON.stringify(state, null, 2) + '\n')
  console.log(`wrote ${outPath} (${state.workouts.length} workouts)`)
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
