// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * Parity test fixture cases for Phase 5 (Timers & Guest Mode).
 *
 * Sources:
 * - supersetFlow.js: restAfterSet, restOnRecheck, restSecFor, warmupRestSecFor
 * - reminder-shim.js (transcribed from mobile.js:88-126): reminderDays
 */

// Fixed timestamp: 2026-06-15T12:00:00.000Z (Monday)
const NOW_MS = 1781524800000;

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
  routines: [
    { id: 'rA', name: 'Routine A', exercises: ['0025'] },
    { id: 'rB', name: 'Routine B', exercises: ['0042'] },
    { id: 'rC', name: 'Routine C', exercises: ['0043'] },
  ],
  week: {},
  dayPlan: {},
  exWeights: {},
  workouts: [],
  active: null,
  customEx: [],
  gifSize: 'full',
  workoutView: 'cards',
  wc: { steppers: true, setShortcuts: false, pairButtons: false, exerciseButtons: false },
  reminder: { on: false, time: '08:00', tz: null },
  effort: null,
  autoBackup: false,
  equipProfiles: [],
  activeEquipId: null,
  equipFilterOn: false,
  exNotes: {},
  favEx: [],
  weekStart: 1,
  wdec: 1,
  barWeights: {},
  gymCards: [],
  lastGymCardId: null,
  checkIn: false,
  weighIn: true,
};

export const cases = [
  // -------------------------------------------------------------------------
  // supersetFlow.restAfterSet
  // -------------------------------------------------------------------------
  {
    id: 'p5-sf-001',
    fn: 'supersetFlow.restAfterSet',
    args: [{ unitDone: false, lastUnit: false }],
    from: 'supersetFlow.js:47-49: set done mid-exercise, not last unit -> true',
  },
  {
    id: 'p5-sf-002',
    fn: 'supersetFlow.restAfterSet',
    args: [{ unitDone: false, lastUnit: true }],
    from: 'supersetFlow.js:47-49: set done mid-exercise, last unit -> true',
  },
  {
    id: 'p5-sf-003',
    fn: 'supersetFlow.restAfterSet',
    args: [{ unitDone: true, lastUnit: false }],
    from: 'supersetFlow.js:47-49: unit done, not last unit -> true',
  },
  {
    id: 'p5-sf-004',
    fn: 'supersetFlow.restAfterSet',
    args: [{ unitDone: true, lastUnit: true }],
    from: 'supersetFlow.js:47-49: unit done and last unit of workout -> false',
  },

  // -------------------------------------------------------------------------
  // supersetFlow.restOnRecheck
  // -------------------------------------------------------------------------
  {
    id: 'p5-sf-005',
    fn: 'supersetFlow.restOnRecheck',
    args: [{ timerRunning: true, unitDone: false, lastUnit: false }],
    from: 'supersetFlow.js:64-66: timer already running -> false',
  },
  {
    id: 'p5-sf-006',
    fn: 'supersetFlow.restOnRecheck',
    args: [{ timerRunning: true, unitDone: true, lastUnit: false }],
    from: 'supersetFlow.js:64-66: timer running, unit done -> false',
  },
  {
    id: 'p5-sf-007',
    fn: 'supersetFlow.restOnRecheck',
    args: [{ timerRunning: false, unitDone: false, lastUnit: false }],
    from: 'supersetFlow.js:64-66: timer not running, not last unit -> true',
  },
  {
    id: 'p5-sf-008',
    fn: 'supersetFlow.restOnRecheck',
    args: [{ timerRunning: false, unitDone: true, lastUnit: true }],
    from: 'supersetFlow.js:64-66: timer not running, unit done & last unit -> false',
  },

  // -------------------------------------------------------------------------
  // supersetFlow.restSecFor
  // -------------------------------------------------------------------------
  {
    id: 'p5-sf-009',
    fn: 'supersetFlow.restSecFor',
    args: [
      [{ id: '0025', target: {} }],
      [0],
      90,
    ],
    from: 'supersetFlow.js:84-92: plain exercise inherits defaultRestSec 90',
  },
  {
    id: 'p5-sf-010',
    fn: 'supersetFlow.restSecFor',
    args: [
      [{ id: '0025', target: { restSec: 120 } }],
      [0],
      90,
    ],
    from: 'supersetFlow.js:84-92: own target.restSec 120 overrides default',
  },
  {
    id: 'p5-sf-011',
    fn: 'supersetFlow.restSecFor',
    args: [
      [
        { id: '0025', target: { restSec: 60 } },
        { id: '0026', target: { restSec: 150 } },
      ],
      [0, 1],
      90,
    ],
    from: 'supersetFlow.js:84-92: superset group takes longest rest (150)',
  },
  {
    id: 'p5-sf-012',
    fn: 'supersetFlow.restSecFor',
    args: [
      [{ id: '0025', target: {} }],
      [0],
      0,
    ],
    from: 'supersetFlow.js:84-92: defaultRestSec 0 with no own rest gives 0',
  },
  {
    id: 'p5-sf-013',
    fn: 'supersetFlow.restSecFor',
    args: [
      [{ id: '0025', target: { restSec: 60 } }],
      [0],
      0,
    ],
    from: 'supersetFlow.js:84-92: defaultRestSec 0 with own restSec 60 gives 60',
  },
  {
    id: 'p5-sf-014',
    fn: 'supersetFlow.restSecFor',
    args: [
      [{ id: '0025', target: {} }],
      [],
      90,
    ],
    from: 'supersetFlow.js:84-92: empty unit array falls back to defaultRestSec',
  },

  // -------------------------------------------------------------------------
  // supersetFlow.warmupRestSecFor
  // -------------------------------------------------------------------------
  {
    id: 'p5-sf-015',
    fn: 'supersetFlow.warmupRestSecFor',
    args: [
      {
        target: { warmupRestSec: 45 },
        sets: [
          { phase: 'work', done: true },
          { phase: 'work', done: false },
        ],
      },
      0,
      90,
    ],
    from: 'supersetFlow.js:103-111: work set returns workRestSec (90)',
  },
  {
    id: 'p5-sf-016',
    fn: 'supersetFlow.warmupRestSecFor',
    args: [
      {
        target: { warmupRestSec: 45 },
        sets: [
          { phase: 'warmup', done: true },
          { phase: 'warmup', done: false },
          { phase: 'work', done: false },
        ],
      },
      0,
      90,
    ],
    from: 'supersetFlow.js:103-111: warm-up followed by undone warm-up gets own warmupRestSec (45)',
  },
  {
    id: 'p5-sf-017',
    fn: 'supersetFlow.warmupRestSecFor',
    args: [
      {
        target: { warmupRestSec: 45 },
        sets: [
          { phase: 'warmup', done: true },
          { phase: 'work', done: false },
        ],
      },
      0,
      90,
    ],
    from: 'supersetFlow.js:103-111: last warm-up before work set returns workRestSec (90)',
  },
  {
    id: 'p5-sf-018',
    fn: 'supersetFlow.warmupRestSecFor',
    args: [
      {
        target: {},
        sets: [
          { phase: 'warmup', done: true },
          { phase: 'warmup', done: false },
        ],
      },
      0,
      90,
    ],
    from: 'supersetFlow.js:103-111: warm-up with no warmupRestSec returns workRestSec (90)',
  },

  // -------------------------------------------------------------------------
  // reminder.reminderDays
  // -------------------------------------------------------------------------
  {
    id: 'p5-rem-001',
    fn: 'reminder.reminderDays',
    args: [
      { ...defaultState, reminder: { on: false, time: '20:00' } },
      NOW_MS,
    ],
    from: 'mobile.js:98: reminder off -> []',
  },
  {
    id: 'p5-rem-002',
    fn: 'reminder.reminderDays',
    args: [
      { ...defaultState, reminder: { on: true, time: '20:00' }, routines: [] },
      NOW_MS,
    ],
    from: 'mobile.js:99: reminder on with no routines -> []',
  },
  {
    id: 'p5-rem-003',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: '20:00' },
        week: { 1: ['rA'] },
      },
      NOW_MS,
    ],
    from: 'mobile.js:106-124: Mondays only across 60 days (approx 9 Mondays)',
  },
  {
    id: 'p5-rem-004',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: '20:00' },
        week: { 1: ['rA'] },
        workouts: [{ d: '2026-06-15' }],
      },
      NOW_MS,
    ],
    from: 'mobile.js:110: workout completed on 2026-06-15 suppresses today (first reminder is next Monday, offset 7 -> id 1007)',
  },
  {
    id: 'p5-rem-005',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: '20:00' },
        week: { 1: ['rA'] },
        dayPlan: {
          '2026-06-15': ['rest'],
          '2026-06-16': ['rB'],
        },
      },
      NOW_MS,
    ],
    from: 'mobile.js:112: dayPlan rest overrides Monday; Tuesday override adds rB',
  },
  {
    id: 'p5-rem-006',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: '20:00' },
        week: { 1: ['rA', 'rB', 'rC'] },
      },
      NOW_MS,
    ],
    from: 'mobile.js:114: 3 routines on a day formats as "{0} routines" label',
  },
  {
    id: 'p5-rem-007',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: 'ab:cd' },
        week: { 1: ['rA'] },
      },
      NOW_MS,
    ],
    from: 'mobile.js:103: malformed time string returns []',
  },
  {
    id: 'p5-rem-008',
    fn: 'reminder.reminderDays',
    args: [
      {
        ...defaultState,
        reminder: { on: true, time: '04:00' },
        week: { 1: ['rA'] },
      },
      NOW_MS,
    ],
    from: 'mobile.js:117: time 04:00 is already past everywhere at 12:00 UTC, skips today',
  },
];
