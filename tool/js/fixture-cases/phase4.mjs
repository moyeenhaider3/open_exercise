// SPDX-License-Identifier: AGPL-3.0-or-later

import { UNDEF } from './helpers.mjs';
import { EXIDX } from '../../../third_party/opengym/lib/exercises.js';
import { FATIGUE_LEVELS } from '../shims/muscle-view-shim.js';

// Fixed timestamp: 2026-06-15T12:00:00.000Z (Monday)
const NOW_MS = 1781524800000;
const TODAY_ISO = '2026-06-15';

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
  bodyweight: [
    { d: '2026-06-01', w: 75.0 },
    { d: '2026-06-14', w: 75.5 },
  ],
  routines: [],
  week: {},
  dayPlan: {},
  exWeights: { '0025': { w: 80, d: '2026-06-14' } },
  workouts: [],
  active: null,
  customEx: [
    {
      id: 'custom-lat',
      n: 'Custom Lat Pulldown',
      bp: 'back',
      eq: 'cable',
      muscleWeights: { 'upper-back': 1, biceps: 0.5 },
    },
  ],
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

// Workouts with fixed timestamps relative to NOW_MS
// w1: 1 day ago (2026-06-14T10:00:00Z) - Bench press with rated hard sets (RIR 1) and warm-up
// w2: 10 days ago (2026-06-05T10:00:00Z) - Custom lat pulldown with done work sets, no rating
// w3: 40 days ago (2026-05-06T10:00:00Z) - Bench press (older, for 90d window / strength)
const w1Time = NOW_MS - 1 * 86400000;
const w2Time = NOW_MS - 10 * 86400000;
const w3Time = NOW_MS - 40 * 86400000;

const sampleWorkouts = [
  {
    id: 'w1',
    d: '2026-06-14',
    start: w1Time,
    end: w1Time + 3600000,
    entries: [
      {
        id: '0025',
        sets: [
          { weight: 40, reps: 10, done: true, warmup: true },
          { weight: 80, reps: 8, done: true, rir: 1 },
          { weight: 80, reps: 7, done: true, rir: 2 },
          { weight: 80, reps: 6, done: false },
        ],
      },
    ],
  },
  {
    id: 'w2',
    d: '2026-06-05',
    start: w2Time,
    end: w2Time + 2700000,
    entries: [
      {
        id: 'custom-lat',
        exercise: {
          id: 'custom-lat',
          n: 'Custom Lat Pulldown',
          muscleWeights: { 'upper-back': 1, biceps: 0.5 },
        },
        sets: [
          { weight: 50, reps: 10, done: true },
          { weight: 55, reps: 8, done: true },
        ],
      },
    ],
  },
  {
    id: 'w3',
    d: '2026-05-06',
    start: w3Time,
    end: w3Time + 3000000,
    entries: [
      {
        id: '0025',
        sets: [
          { weight: 75, reps: 10, done: true },
          { weight: 75, reps: 8, done: true },
        ],
      },
    ],
  },
];

const stateWithWorkouts = {
  ...defaultState,
  workouts: sampleWorkouts,
};

const stateWithoutRated = {
  ...defaultState,
  workouts: [sampleWorkouts[1]], // only w2, no rated sets
};

const stateLbUnit = {
  ...defaultState,
  unit: 'lb',
  bodyweight: [
    { d: '2026-06-01', w: 165.0 },
    { d: '2026-06-14', w: 166.0 },
  ],
  workouts: sampleWorkouts,
};

export const cases = [
  // -------------------------------------------------------------------------
  // muscles.musclesOf
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-001',
    fn: 'muscles.musclesOf',
    args: [EXIDX['0025']],
    from: 'lib/muscles.js:203-241 > catalogue exercise 0025',
  },
  {
    id: 'p4-muscles-002',
    fn: 'muscles.musclesOf',
    args: [{ id: 'custom-lat', muscleWeights: { 'upper-back': 1, biceps: 0.5 } }],
    from: 'lib/muscles.js:203-241 > custom exercise with muscleWeights',
  },
  {
    id: 'p4-muscles-003',
    fn: 'muscles.musclesOf',
    args: [{ primaries: ['quadriceps'], secondaries: ['gluteal', 'calves'] }],
    from: 'lib/muscles.js:203-241 > exercise with primaries and secondaries',
  },

  // -------------------------------------------------------------------------
  // muscles.loadOf
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-004',
    fn: 'muscles.loadOf',
    args: [
      [
        { id: '0025', sets: 3 },
        { id: '0025', sets: 0 },
      ],
    ],
    from: 'lib/muscles.js:249-260 > items with sets 0 skipped and sets > 0',
  },
  {
    id: 'p4-muscles-005',
    fn: 'muscles.loadOf',
    args: [
      [
        { id: '0025', sets: 4 },
        { id: 'custom-lat', ex: { muscleWeights: { 'upper-back': 1 } }, sets: 2 },
      ],
    ],
    from: 'lib/muscles.js:249-260 > multiple exercises including custom weights',
  },

  // -------------------------------------------------------------------------
  // muscles.loadOfWorkouts
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-006',
    fn: 'muscles.loadOfWorkouts',
    args: [sampleWorkouts, UNDEF],
    from: 'lib/muscles.js:268-270 > load of finished workouts without pick predicate',
  },

  // -------------------------------------------------------------------------
  // muscles.loadOfActive
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-007',
    fn: 'muscles.loadOfActive',
    args: [
      {
        entries: [
          {
            id: '0025',
            sets: [
              { weight: 60, reps: 5, done: true, warmup: true },
              { weight: 80, reps: 5, done: true },
              { weight: 80, reps: 5, done: false },
            ],
          },
        ],
      },
    ],
    from: 'lib/muscles.js:291-293 > load of in-progress active workout',
  },

  // -------------------------------------------------------------------------
  // muscles.loadOfRoutine
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-008',
    fn: 'muscles.loadOfRoutine',
    args: [
      {
        id: 'r-chest-back',
        ex: [
          { id: '0025', sets: 4 },
          { id: 'custom-lat', ex: { muscleWeights: { 'upper-back': 1 } }, sets: 3 },
        ],
      },
    ],
    from: 'lib/muscles.js:287-288 > load a routine would produce',
  },

  // -------------------------------------------------------------------------
  // muscles.levelsOf
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-009',
    fn: 'muscles.levelsOf',
    args: [{ chest: 8, triceps: 3.2, deltoids: 1.6, biceps: 0.8 }, UNDEF],
    from: 'lib/muscles.js:305-327 > relative levels (no thresholds)',
  },
  {
    id: 'p4-muscles-010',
    fn: 'muscles.levelsOf',
    args: [
      { chest: 0.55, triceps: 0.4, deltoids: 0.15, biceps: 0.05 },
      FATIGUE_LEVELS,
    ],
    from: 'lib/muscles.js:305-327 > absolute fatigue levels including exclusive 0.55 rule',
  },
  {
    id: 'p4-muscles-011',
    fn: 'muscles.levelsOf',
    args: [{}, UNDEF],
    from: 'lib/muscles.js:305-327 > empty load returns all zeros',
  },

  // -------------------------------------------------------------------------
  // muscles.rankOf
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-012',
    fn: 'muscles.rankOf',
    args: [{ chest: 2, biceps: 2, abs: 1 }],
    from: 'lib/muscles.js:330-335 > rankOf with ties falling back to MUSCLES order',
  },
  {
    id: 'p4-muscles-013',
    fn: 'muscles.rankOf',
    args: [{}],
    from: 'lib/muscles.js:330-335 > rankOf with empty load',
  },

  // -------------------------------------------------------------------------
  // muscles.muscleBalanceWindow
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscles-014',
    fn: 'muscles.muscleBalanceWindow',
    args: [sampleWorkouts, 0, NOW_MS, TODAY_ISO, 1],
    from: 'lib/muscles.js:278-284 > window 0 (all workouts)',
  },
  {
    id: 'p4-muscles-015',
    fn: 'muscles.muscleBalanceWindow',
    args: [sampleWorkouts, 7, NOW_MS, TODAY_ISO, 1],
    from: 'lib/muscles.js:278-284 > window 7 with Monday week start',
  },
  {
    id: 'p4-muscles-016',
    fn: 'muscles.muscleBalanceWindow',
    args: [sampleWorkouts, 7, NOW_MS, TODAY_ISO, 0],
    from: 'lib/muscles.js:278-284 > window 7 with Sunday week start',
  },
  {
    id: 'p4-muscles-017',
    fn: 'muscles.muscleBalanceWindow',
    args: [sampleWorkouts, 30, NOW_MS, TODAY_ISO, 1],
    from: 'lib/muscles.js:278-284 > window 30 (last 30 days)',
  },

  // -------------------------------------------------------------------------
  // recoveryView.fatigueStateOf
  // -------------------------------------------------------------------------
  {
    id: 'p4-recoveryview-001',
    fn: 'recoveryView.fatigueStateOf',
    args: [0.24],
    from: 'lib/recovery-view.js:11-17 > below 0.25 is ready',
  },
  {
    id: 'p4-recoveryview-002',
    fn: 'recoveryView.fatigueStateOf',
    args: [0.25],
    from: 'lib/recovery-view.js:11-17 > 0.25 is recovering (inclusive)',
  },
  {
    id: 'p4-recoveryview-003',
    fn: 'recoveryView.fatigueStateOf',
    args: [0.5],
    from: 'lib/recovery-view.js:11-17 > 0.50 is recovering (inclusive)',
  },
  {
    id: 'p4-recoveryview-004',
    fn: 'recoveryView.fatigueStateOf',
    args: [0.51],
    from: 'lib/recovery-view.js:11-17 > above 0.50 is fatigued',
  },

  // -------------------------------------------------------------------------
  // muscleView.muscleBalance
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscleview-001',
    fn: 'muscleView.muscleBalance',
    args: [stateWithWorkouts, 7, false, NOW_MS, TODAY_ISO],
    from: 'views/Stats.jsx:124-143 > muscleBalance > hard false in week window',
  },
  {
    id: 'p4-muscleview-002',
    fn: 'muscleView.muscleBalance',
    args: [stateWithWorkouts, 30, true, NOW_MS, TODAY_ISO],
    from: 'views/Stats.jsx:124-143 > muscleBalance > hard true with rated sets (on=true)',
  },
  {
    id: 'p4-muscleview-003',
    fn: 'muscleView.muscleBalance',
    args: [stateWithoutRated, 7, true, NOW_MS, TODAY_ISO],
    from: 'views/Stats.jsx:124-143 > muscleBalance > hard true without rated sets (on=false)',
  },
  {
    id: 'p4-muscleview-004',
    fn: 'muscleView.muscleBalance',
    args: [{ ...defaultState, workouts: [] }, 7, false, NOW_MS, TODAY_ISO],
    from: 'views/Stats.jsx:124-143 > muscleBalance > empty window',
  },

  // -------------------------------------------------------------------------
  // muscleView.fatigueView
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscleview-005',
    fn: 'muscleView.fatigueView',
    args: [stateWithWorkouts, NOW_MS],
    from: 'views/Stats.jsx:114-118 > fatigueView with workouts',
  },
  {
    id: 'p4-muscleview-006',
    fn: 'muscleView.fatigueView',
    args: [stateLbUnit, NOW_MS],
    from: 'views/Stats.jsx:114-118 > fatigueView in lb unit with bodyweight',
  },

  // -------------------------------------------------------------------------
  // muscleView.strengthView
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscleview-007',
    fn: 'muscleView.strengthView',
    args: [stateWithWorkouts, NOW_MS, null],
    from: 'views/Stats.jsx:115,134-138 > strengthView without selection',
  },
  {
    id: 'p4-muscleview-008',
    fn: 'muscleView.strengthView',
    args: [stateWithWorkouts, NOW_MS, 'chest'],
    from: 'views/Stats.jsx:115,134-138 > strengthView with selected muscle chest',
  },
  {
    id: 'p4-muscleview-009',
    fn: 'muscleView.strengthView',
    args: [stateLbUnit, NOW_MS, 'chest'],
    from: 'views/Stats.jsx:115,134-138 > strengthView in lb unit with selected muscle',
  },

  // -------------------------------------------------------------------------
  // muscleView.muscleIndex
  // -------------------------------------------------------------------------
  {
    id: 'p4-muscleview-010',
    fn: 'muscleView.muscleIndex',
    args: [stateWithWorkouts, ['0025', 'custom-lat']],
    from: 'components/MuscleExplorer.jsx:34-37 > muscleIndex for catalogue and custom ids',
  },
  {
    id: 'p4-muscleview-011',
    fn: 'muscleView.muscleIndex',
    args: [stateWithWorkouts, ['0025']],
    from: 'components/MuscleExplorer.jsx:34-37 > muscleIndex for single exercise',
  },
];
