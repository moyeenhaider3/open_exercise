// SPDX-License-Identifier: AGPL-3.0-or-later

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

const sampleStateForUnits = {
  ...defaultState,
  unit: 'kg',
  targetW: 80,
  bodyweight: [{ d: '2026-01-01', w: 82.4, t: 1 }],
  exWeights: { '0025': { w: 80, d: '2026-01-01' }, legacy: 100 },
  barWeights: { '0025': 20 },
  routines: [
    {
      id: 'r',
      ex: [
        { id: '0025', sets: 3, reps: 5, weight: 80, inc: 2.5, warmup: [{ weight: 40, reps: 8 }] },
        { id: 'plank', mode: 'time', sec: 30, inc: 5 },
      ],
    },
  ],
  workouts: [
    {
      id: 'w',
      vol: 700,
      bw: 82.4,
      entries: [
        {
          id: '0025',
          topW: 80,
          target: { weight: 80 },
          sets: [
            { w: 80, r: 5, done: true, drops: [{ w: 60, r: 5 }] },
            {
              sides: {
                L: { w: 20, r: 10, done: true },
                R: { w: 20, r: 10, done: true },
              },
              done: true,
            },
          ],
        },
      ],
    },
  ],
  active: {
    id: 'a',
    bw: 82.4,
    entries: [{ id: '0025', sets: [{ w: 82.5, r: 5, done: false }] }],
  },
  workoutView: 'list',
};

const finishBackfillState = {
  customEx: [],
  exWeights: { '0025': { w: 90, d: '2026-09-20' } },
  workouts: [],
  active: {
    id: 'w_active_backfill',
    d: '2026-09-28',
    start: 1700000000000,
    name: 'Workout Backfill',
    backfill: { durationMin: 45, replaceId: null },
    entries: [
      {
        id: '0025',
        sets: [
          { w: 100, r: 5, done: true },
        ],
      },
    ],
  },
};

// ---------------------------------------------------------------------------
// Shared states for effort + viewAgg cases
// ---------------------------------------------------------------------------

const T_2026_01_01 = 1735689600000; // 2026-01-01T00:00:00.000Z
const T_2026_01_08 = 1736294400000; // 2026-01-08T00:00:00.000Z
const T_2026_01_15 = 1736899200000; // 2026-01-15T00:00:00.000Z

// State with rated sets for effort fixtures (days=0 → all history, no Date.now())
const effortStateRir = {
  ...defaultState,
  effort: 'rir',
  workouts: [
    {
      id: 'w1', d: '2026-01-01', start: T_2026_01_01, end: T_2026_01_01 + 3600000,
      vol: 200,
      entries: [
        {
          id: '0025', sets: [
            { w: 80, r: 5, done: true, rir: 2 },
            { w: 80, r: 5, done: true, rir: 1 },
            { w: 80, r: 5, done: true, rir: 1 },
            { w: 75, r: 8, done: true, rir: 3 },
            { w: 70, r: 10, done: true, rir: 5 },
            { w: 60, r: 12, done: true, warmup: true }, // warmup — excluded
          ],
        },
      ],
    },
    {
      id: 'w2', d: '2026-01-08', start: T_2026_01_08, end: T_2026_01_08 + 4200000,
      vol: 300,
      entries: [
        {
          id: '0025', sets: [
            { w: 85, r: 5, done: true, rir: 2 },
            { w: 85, r: 5, done: true, rir: 2 },
            { w: 85, r: 4, done: true, rir: 0 },   // failure
            { w: 80, r: 5, done: true, rir: 3 },
            { w: 80, r: 5, done: true, rir: 4 },
            { w: 80, r: 6, done: true, rir: 6 },   // tail (4+)
          ],
        },
      ],
    },
    {
      id: 'w3', d: '2026-01-15', start: T_2026_01_15, end: T_2026_01_15 + 3000000,
      vol: 150,
      entries: [
        {
          id: '0025', sets: [
            { w: 82.5, r: 5, done: true, rir: 1 },
            { w: 82.5, r: 5, done: true, rir: 1 },
            { w: 82.5, r: 5, done: true, rir: 2 },
            { w: 80, r: 5, done: true, rir: 3 },
          ],
        },
      ],
    },
  ],
};

// State with RPE-style sets (no explicit effort setting → displayScale picks from history)
const effortStateRpe = {
  ...defaultState,
  effort: null,
  workouts: [
    {
      id: 'w_rpe', d: '2026-01-01', start: T_2026_01_01, end: T_2026_01_01 + 3600000,
      vol: 100,
      entries: [
        {
          id: '0025', sets: [
            { w: 80, r: 5, done: true, rpe: 8 },
            { w: 80, r: 5, done: true, rpe: 8.5 },
            { w: 80, r: 5, done: true, rpe: 9 },
            { w: 75, r: 8, done: true, rpe: 7 },
            { w: 70, r: 10, done: true, rpe: 7 },
          ],
        },
      ],
    },
  ],
};

// State with no rated sets
const emptyEffortState = { ...defaultState, workouts: [] };

// ---------------------------------------------------------------------------
// effort fixture cases
// ---------------------------------------------------------------------------
export const cases = [
  // backfill.workoutsOn
  {
    id: 'p31-backfill-001',
    fn: 'backfill.workoutsOn',
    args: [
      {
        workouts: [
          { id: 'a', d: '2026-01-01', start: 10 },
          { id: 'b', d: '2026-01-02', start: 10 },
          { id: 'c', d: '2026-01-02', start: 20 },
        ],
      },
      '2026-01-02',
    ],
    from: 'backfill.test.js > workoutsOn > returns every workout of that day and nothing else',
    vitest: [
      { id: 'b', d: '2026-01-02', start: 10 },
      { id: 'c', d: '2026-01-02', start: 20 },
    ],
  },
  {
    id: 'p31-backfill-002',
    fn: 'backfill.workoutsOn',
    args: [
      {
        workouts: [
          { id: 'a', d: '2026-01-01', start: 10 },
        ],
      },
      '2026-01-02',
    ],
    from: 'backfill.test.js > workoutsOn > returns empty list if no workouts on that day',
    vitest: [],
  },
  {
    id: 'p31-backfill-003',
    fn: 'backfill.workoutsOn',
    args: [{}, '2026-01-02'],
    from: 'backfill.test.js > workoutsOn > returns empty list if workouts property missing',
    vitest: [],
  },

  // backfill.backfillEnd
  {
    id: 'p31-backfill-004',
    fn: 'backfill.backfillEnd',
    args: [{ start: 1700000000000, backfill: { durationMin: 45 } }],
    from: 'backfill.test.js > backfillEnd > ends after the given duration (45 min)',
    vitest: 1700002700000,
  },
  {
    id: 'p31-backfill-005',
    fn: 'backfill.backfillEnd',
    args: [{ start: 1700000000000, backfill: {} }],
    from: 'backfill.test.js > backfillEnd > defaults to 60 min when durationMin missing',
    vitest: 1700003600000,
  },
  {
    id: 'p31-backfill-006',
    fn: 'backfill.backfillEnd',
    args: [{ start: 1700000000000, backfill: { durationMin: 0 } }],
    from: 'backfill.test.js > backfillEnd > durationMin 0 falls back to 60 min',
    vitest: 1700003600000,
  },

  // backfill.insertChronological
  {
    id: 'p31-backfill-007',
    fn: 'backfill.insertChronological',
    args: [
      [
        { id: 'b', d: '2026-01-05', start: 10 },
        { id: 'c', d: '2026-01-09', start: 10 },
      ],
      { id: 'a', d: '2026-01-01', start: 10 },
    ],
    from: 'backfill.test.js > insertChronological > inserts at the front',
  },
  {
    id: 'p31-backfill-008',
    fn: 'backfill.insertChronological',
    args: [
      [
        { id: 'a', d: '2026-01-01', start: 10 },
        { id: 'c', d: '2026-01-05', start: 20 },
        { id: 'd', d: '2026-01-09', start: 10 },
      ],
      { id: 'b', d: '2026-01-05', start: 15 },
    ],
    from: 'backfill.test.js > insertChronological > places between items',
  },
  {
    id: 'p31-backfill-009',
    fn: 'backfill.insertChronological',
    args: [
      [
        { id: 'a', d: '2026-01-01', start: 10 },
        { id: 'b', d: '2026-01-05', start: 10 },
      ],
      { id: 'c', d: '2026-01-09', start: 10 },
    ],
    from: 'backfill.test.js > insertChronological > appends at the end',
  },
  {
    id: 'p31-backfill-010',
    fn: 'backfill.insertChronological',
    args: [
      [
        { id: 'a', d: '2026-01-05', start: 10 },
      ],
      { id: 'b', d: '2026-01-05', start: 10 },
    ],
    from: 'backfill.test.js > insertChronological > places after equal keys (<= tie rule)',
  },
  {
    id: 'p31-backfill-011',
    fn: 'backfill.insertChronological',
    args: [
      [],
      { id: 'a', d: '2026-01-01', start: 10 },
    ],
    from: 'backfill.test.js > insertChronological > inserts into empty list',
  },

  // backfill.completeBackfill
  {
    id: 'p31-backfill-012',
    fn: 'backfill.completeBackfill',
    args: [
      [
        { id: 'a', d: '2026-01-01', start: 10 },
        { id: 'b', d: '2026-01-05', start: 10 },
        { id: 'd', d: '2026-01-09', start: 10 },
      ],
      { backfill: { durationMin: 60, replaceId: null } },
      { id: 'x', d: '2026-01-05', start: 5 },
    ],
    from: 'backfill.test.js > completeBackfill > adds a second workout on a day in order when replaceId is null',
  },
  {
    id: 'p31-backfill-013',
    fn: 'backfill.completeBackfill',
    args: [
      [
        { id: 'a', d: '2026-01-01', start: 10 },
        { id: 'b', d: '2026-01-05', start: 10 },
        { id: 'd', d: '2026-01-09', start: 10 },
      ],
      { backfill: { durationMin: 60, replaceId: 'b' } },
      { id: 'x', d: '2026-01-05', start: 30 },
    ],
    from: 'backfill.test.js > completeBackfill > replaces the chosen workout',
  },

  // units.convertWeight
  {
    id: 'p31-units-001',
    fn: 'units.convertWeight',
    args: [100, 'kg', 'lb'],
    from: 'units.test.js > convertWeight > 100 kg to lb',
    vitest: 220.5,
  },
  {
    id: 'p31-units-002',
    fn: 'units.convertWeight',
    args: [225, 'lb', 'kg'],
    from: 'units.test.js > convertWeight > 225 lb to kg',
    vitest: 102,
  },
  {
    id: 'p31-units-003',
    fn: 'units.convertWeight',
    args: [60, 'kg', 'kg'],
    from: 'units.test.js > convertWeight > leaves value alone for same unit',
    vitest: 60,
  },
  {
    id: 'p31-units-004',
    fn: 'units.convertWeight',
    args: [null, 'kg', 'lb'],
    from: 'units.test.js > convertWeight > null passthrough',
    vitest: null,
  },
  {
    id: 'p31-units-005',
    fn: 'units.convertWeight',
    args: ['', 'kg', 'lb'],
    from: 'units.test.js > convertWeight > empty string passthrough',
    vitest: '',
  },
  {
    id: 'p31-units-006',
    fn: 'units.convertWeight',
    args: ['abc', 'kg', 'lb'],
    from: 'units.test.js > convertWeight > non-numeric string passthrough',
    vitest: 'abc',
  },
  {
    id: 'p31-units-007',
    fn: 'units.convertWeight',
    args: [60, 'kg', 'lb'],
    from: 'units.test.js > convertWeight > 60 kg to lb (rounds lb to half)',
    vitest: 132.5,
  },

  // units.convertBodyWeight
  {
    id: 'p31-units-008',
    fn: 'units.convertBodyWeight',
    args: [78.6, 'kg', 'lb'],
    from: 'units.test.js > convertBodyWeight > 78.6 kg to lb (QA C15)',
    vitest: 173.3,
  },
  {
    id: 'p31-units-009',
    fn: 'units.convertBodyWeight',
    args: [173.3, 'lb', 'kg'],
    from: 'units.test.js > convertBodyWeight > 173.3 lb to kg (QA C15 round trip)',
    vitest: 78.6,
  },
  {
    id: 'p31-units-010',
    fn: 'units.convertBodyWeight',
    args: [78.6, 'kg', 'kg'],
    from: 'units.test.js > convertBodyWeight > same unit passthrough',
    vitest: 78.6,
  },
  {
    id: 'p31-units-011',
    fn: 'units.convertBodyWeight',
    args: [null, 'kg', 'lb'],
    from: 'units.test.js > convertBodyWeight > null passthrough',
    vitest: null,
  },

  // units.convertStateUnit
  {
    id: 'p31-units-012',
    fn: 'units.convertStateUnit',
    args: [sampleStateForUnits, 'lb'],
    from: 'units.test.js > convertStateUnit > converts every stored weight to lb',
  },
  {
    id: 'p31-units-013',
    fn: 'units.convertStateUnit',
    args: [sampleStateForUnits, 'kg'],
    from: 'units.test.js > convertStateUnit > is a no-op for the unit already in use',
  },

  // finish.completeWorkout
  {
    id: 'p31-finish-001',
    fn: 'finish.completeWorkout',
    args: [finishBackfillState],
    from: 'sheets.jsx > doFinishWorkout > backfilled workout finish',
    vitest: {
      workout: {
        id: 'w_active_backfill',
        d: '2026-09-28',
        start: 1700000000000,
        end: 1700002700000,
        routineIds: [],
        routineId: null,
        name: 'Workout Backfill',
        entries: [
          {
            id: '0025',
            sets: [
              {
                w: 100,
                r: 5,
                done: true,
              },
            ],
            topW: 100,
            target: null,
          },
        ],
        prs: [],
        vol: 500,
      },
      prs: [],
      e1prs: [],
      exWeights: {
        '0025': {
          w: 90,
          d: '2026-09-20',
        },
      },
      past: true,
      replaceId: null,
    },
  },

  // ---------------------------------------------------------------------------
  // effort cases (p31-effort-001 ... p31-effort-NNN)
  // All use days=0 so inWindow always returns true (no Date.now() dependency).
  // ---------------------------------------------------------------------------

  // hasEffort
  {
    id: 'p31-effort-001',
    fn: 'effort.hasEffort',
    args: [effortStateRir],
    from: 'effort.js > hasEffort > true when rated sets exist',
    vitest: true,
  },
  {
    id: 'p31-effort-002',
    fn: 'effort.hasEffort',
    args: [emptyEffortState],
    from: 'effort.js > hasEffort > false when no workouts',
    vitest: false,
  },

  // displayScale
  {
    id: 'p31-effort-003',
    fn: 'effort.displayScale',
    args: [effortStateRir],
    from: 'effort.js > displayScale > profile effort rir → rir',
    vitest: 'rir',
  },
  {
    id: 'p31-effort-004',
    fn: 'effort.displayScale',
    args: [effortStateRpe],
    from: 'effort.js > displayScale > no profile setting but RPE-heavy history → rpe',
    vitest: 'rpe',
  },

  // scaleName
  {
    id: 'p31-effort-005',
    fn: 'effort.scaleName',
    args: ['rir'],
    from: 'effort.js > scaleName > rir heading string',
  },
  {
    id: 'p31-effort-006',
    fn: 'effort.scaleName',
    args: ['rpe'],
    from: 'effort.js > scaleName > rpe heading string',
  },

  // avgRir
  {
    id: 'p31-effort-007',
    fn: 'effort.avgRir',
    args: [[{ rir: 2 }, { rir: 4 }, { rpe: 8 }]], // rpe 8 = rir 2
    from: 'effort.js > avgRir > mixed rir and rpe sets',
    vitest: (2 + 4 + 2) / 3,
  },
  {
    id: 'p31-effort-008',
    fn: 'effort.avgRir',
    args: [[{ w: 80, r: 5 }]], // no effort rating
    from: 'effort.js > avgRir > empty/unrated → null',
    vitest: null,
  },

  // effortSummary (days=0 = all history)
  {
    id: 'p31-effort-009',
    fn: 'effort.effortSummary',
    args: [effortStateRir, 0],
    from: 'effort.js > effortSummary > rated sets above MIN_RATED threshold',
  },
  {
    id: 'p31-effort-010',
    fn: 'effort.effortSummary',
    args: [{ ...defaultState, workouts: [{ id: 'w', d: '2026-01-01', start: T_2026_01_01, vol: 0,
      entries: [{ id: '0025', sets: [
        { w: 80, r: 5, done: true, rir: 2 },
        { w: 80, r: 5, done: true, rir: 3 },
      ] }] }] }, 0],
    from: 'effort.js > effortSummary > below MIN_RATED → avg null',
  },

  // effortHistogram
  {
    id: 'p31-effort-011',
    fn: 'effort.effortHistogram',
    args: [effortStateRir, 0],
    from: 'effort.js > effortHistogram > histogram with 4+ tail bucket populated',
  },

  // isHardSet
  {
    id: 'p31-effort-012',
    fn: 'effort.isHardSet',
    args: [{ rir: 3 }],
    from: 'effort.js > isHardSet > rir at HARD_RIR threshold → true',
    vitest: true,
  },
  {
    id: 'p31-effort-013',
    fn: 'effort.isHardSet',
    args: [{ rir: 4 }],
    from: 'effort.js > isHardSet > rir above HARD_RIR → false',
    vitest: false,
  },
  {
    id: 'p31-effort-014',
    fn: 'effort.isHardSet',
    args: [{ w: 80, r: 5 }],
    from: 'effort.js > isHardSet > no rir/rpe → false',
    vitest: false,
  },

  // ---------------------------------------------------------------------------
  // viewAgg cases (p31-viewagg-001 ...)
  // All epoch inputs are explicit UTC ms to be TZ-independent.
  // ---------------------------------------------------------------------------

  // Shared viewAgg state
  // Three workouts: 2026-01-01 (60 min), 2026-01-08 (70 min), 2026-01-08 (30 min second workout same day)
  // bw: two entries
  // routines: one routine with 3 planned days
  // 2026-01-15 is used as todayIso (weekStart=1 Monday, so weekKey('2026-01-15') = '2026-01-13')

  // heatmapDays — 0-minute day vs multi-workout same day
  {
    id: 'p31-viewagg-001',
    fn: 'viewAgg.heatmapDays',
    args: [{
      ...defaultState,
      workouts: [
        { id: 'wa', d: '2026-01-01', start: T_2026_01_01, end: T_2026_01_01 + 3600000, vol: 200 },
        { id: 'wb', d: '2026-01-08', start: T_2026_01_08, end: T_2026_01_08 + 4200000, vol: 300 },
        { id: 'wc', d: '2026-01-08', start: T_2026_01_08 + 5000000, end: T_2026_01_08 + 6800000, vol: 150 }, // second workout same day
        { id: 'wd', d: '2026-01-15', start: T_2026_01_15, end: T_2026_01_15, vol: 0 }, // 0-minute workout
      ],
    }],
    from: 'components/Heatmap.jsx:11-19 > heatmapDays > multi-workout day and 0-minute day',
  },

  // statsTiles — fixed nowMs/todayIso
  {
    id: 'p31-viewagg-002',
    fn: 'viewAgg.statsTiles',
    args: [
      {
        ...defaultState,
        bodyweight: [
          { d: '2025-12-02', w: 82.0, t: T_2026_01_01 - 30 * 86400000 },
          { d: '2026-01-01', w: 81.0, t: T_2026_01_01 },
        ],
        workouts: [
          { id: 'wa', d: '2026-01-01', start: T_2026_01_01, vol: 200 },
          { id: 'wb', d: '2026-01-08', start: T_2026_01_08, vol: 300 },
        ],
      },
      T_2026_01_15,      // nowMs
      '2026-01-15',       // todayIso (same month as workouts)
    ],
    from: 'views/Stats.jsx:297-302 > statsTiles > two workouts this month, positive bwDelta30',
  },
  {
    id: 'p31-viewagg-003',
    fn: 'viewAgg.statsTiles',
    args: [
      {
        ...defaultState,
        bodyweight: [{ d: '2026-01-01', w: 80.0, t: T_2026_01_01 }], // single entry → bwDelta30 null
        workouts: [],
      },
      T_2026_01_15,
      '2026-01-15',
    ],
    from: 'views/Stats.jsx:297-302 > statsTiles > single bw entry → bwDelta30 null',
    vitest: { workouts: 0, monthW: 0, bwDelta30: null },
  },

  // bodyweightPoints
  {
    id: 'p31-viewagg-004',
    fn: 'viewAgg.bodyweightPoints',
    args: [
      {
        ...defaultState,
        bodyweight: [
          { d: '2025-12-01', w: 83.0, t: T_2026_01_01 - 32 * 86400000 },
          { d: '2026-01-01', w: 82.0, t: T_2026_01_01 },
          { d: '2026-01-08', w: 81.5, t: T_2026_01_08 },
        ],
      },
      30,          // rangeDays=30
      T_2026_01_15, // nowMs → only entries after 2025-12-16 pass
    ],
    from: 'views/Stats.jsx:297-298 > bodyweightPoints > range 30 excludes old entry',
  },
  {
    id: 'p31-viewagg-005',
    fn: 'viewAgg.bodyweightPoints',
    args: [
      {
        ...defaultState,
        bodyweight: [
          { d: '2025-12-01', w: 83.0, t: T_2026_01_01 - 32 * 86400000 },
          { d: '2026-01-01', w: 82.0, t: T_2026_01_01 },
        ],
      },
      0,           // range 0 = all history
      T_2026_01_15,
    ],
    from: 'views/Stats.jsx:297-298 > bodyweightPoints > range 0 returns all entries',
  },

  // exerciseProgress — loaded lift
  {
    id: 'p31-viewagg-006',
    fn: 'viewAgg.exerciseProgress',
    args: [
      {
        ...defaultState,
        customEx: [],
        workouts: [
          {
            id: 'wp1', d: '2026-01-01', start: T_2026_01_01, vol: 400,
            entries: [
              {
                id: '0025', sets: [
                  { w: 80, r: 5, done: true, rir: 2 },
                  { w: 80, r: 5, done: true, rir: 1 },
                ],
              },
            ],
          },
          {
            id: 'wp2', d: '2026-01-08', start: T_2026_01_08, vol: 500,
            entries: [
              {
                id: '0025', sets: [
                  { w: 85, r: 5, done: true, rir: 1 },
                  { w: 85, r: 4, done: true, rir: 0 },
                ],
              },
            ],
          },
        ],
      },
      '0025',
      'rir',
      { '0025': 'Barbell Back Squat' },
    ],
    from: 'views/Stats.jsx:305-435 > exerciseProgress > loaded lift with rir effort',
  },

  // exerciseProgress — reps-only (no weight)
  {
    id: 'p31-viewagg-007',
    fn: 'viewAgg.exerciseProgress',
    args: [
      {
        ...defaultState,
        customEx: [],
        workouts: [
          {
            id: 'wp_bw', d: '2026-01-01', start: T_2026_01_01, vol: 0,
            entries: [
              {
                id: 'pushup', sets: [
                  { r: 20, done: true },
                  { r: 18, done: true },
                ],
              },
            ],
          },
        ],
      },
      'pushup',
      'rir',
      { pushup: 'Push-up' },
    ],
    from: 'views/Stats.jsx:375-380 > exerciseProgress > reps-only exercise (no weight history)',
  },

  // exerciseProgress — exId null → uses first of exHist
  {
    id: 'p31-viewagg-008',
    fn: 'viewAgg.exerciseProgress',
    args: [
      {
        ...defaultState,
        customEx: [],
        workouts: [
          {
            id: 'wp3', d: '2026-01-01', start: T_2026_01_01, vol: 300,
            entries: [
              { id: '0025', sets: [{ w: 80, r: 5, done: true }] },
            ],
          },
        ],
      },
      null,
      'rir',
      { '0025': 'Barbell Back Squat' },
    ],
    from: 'views/Stats.jsx:355-357 > exerciseProgress > null exId falls back to first of exHist',
  },

  // calendarMonth
  {
    id: 'p31-viewagg-009',
    fn: 'viewAgg.calendarMonth',
    args: [
      {
        ...defaultState,
        workouts: [
          { id: 'wm1', d: '2026-01-05', start: T_2026_01_01 + 4 * 86400000, end: T_2026_01_01 + 4 * 86400000 + 3600000, vol: 200 },
          { id: 'wm2', d: '2026-01-12', start: T_2026_01_08 + 4 * 86400000, end: T_2026_01_08 + 4 * 86400000 + 4200000, vol: 300 },
          { id: 'wm3', d: '2026-02-01', start: T_2026_01_15 + 17 * 86400000, vol: 100 }, // different month
        ],
      },
      2026,
      0, // January (0-based)
    ],
    from: 'sheets.jsx:Calendar:1773-1775 > calendarMonth > two January workouts, one February excluded',
  },
  {
    id: 'p31-viewagg-010',
    fn: 'viewAgg.calendarMonth',
    args: [{ ...defaultState, workouts: [] }, 2026, 0],
    from: 'sheets.jsx:Calendar > calendarMonth > empty workouts',
    vitest: { count: 0, vol: 0, ms: 0 },
  },

  // workoutDetailGroups — combined two-routine session
  {
    id: 'p31-viewagg-011',
    fn: 'viewAgg.workoutDetailGroups',
    args: [{
      id: 'wcomb', d: '2026-01-01', start: T_2026_01_01, vol: 500,
      routineIds: ['rA', 'rB'],
      entries: [
        { id: '0025', rid: 'rA', sets: [{ w: 80, r: 5, done: true }, { w: 80, r: 5, done: true }] },
        { id: 'deadlift', rid: 'rA', sets: [{ w: 100, r: 3, done: true }] },
        { id: 'bench', rid: 'rB', sets: [{ w: 60, r: 8, done: true, warmup: true }, { w: 70, r: 5, done: true }] },
      ],
    }],
    from: 'sheets.jsx:WorkoutDetail:1688-1720 > workoutDetailGroups > two-routine combined session',
  },
  // workoutDetailGroups — legacy flat session (no rid)
  {
    id: 'p31-viewagg-012',
    fn: 'viewAgg.workoutDetailGroups',
    args: [{
      id: 'wflat', d: '2026-01-01', start: T_2026_01_01, vol: 200,
      entries: [
        { id: '0025', sets: [{ w: 80, r: 5, done: true }] },
        { id: 'bench', sets: [{ w: 60, r: 8, done: true }] },
      ],
    }],
    from: 'sheets.jsx:WorkoutDetail > workoutDetailGroups > legacy flat session (no rid)',
  },

  // bwGoal
  {
    id: 'p31-viewagg-013',
    fn: 'viewAgg.bwGoal',
    args: [{ ...defaultState, targetW: 80, bodyweight: [{ d: '2026-01-01', w: 82.0, t: T_2026_01_01 }] }],
    from: 'views/Home.jsx:162-165 > bwGoal > losing toward goal',
    vitest: { gap: 2, reached: false, gain: false },
  },
  {
    id: 'p31-viewagg-014',
    fn: 'viewAgg.bwGoal',
    args: [{ ...defaultState, targetW: 85, bodyweight: [{ d: '2026-01-01', w: 82.0, t: T_2026_01_01 }] }],
    from: 'views/Home.jsx:162-165 > bwGoal > gaining toward goal',
    vitest: { gap: 3, reached: false, gain: true },
  },
  {
    id: 'p31-viewagg-015',
    fn: 'viewAgg.bwGoal',
    args: [{ ...defaultState, targetW: 80, bodyweight: [{ d: '2026-01-01', w: 80.02, t: T_2026_01_01 }] }],
    from: 'views/Home.jsx:164 > bwGoal > reached (gap < 0.05)',
    // gap is ~0.02 floating point; omit vitest cross-check to avoid precision mismatch
  },
  {
    id: 'p31-viewagg-016',
    fn: 'viewAgg.bwGoal',
    args: [{ ...defaultState, targetW: null, bodyweight: [] }],
    from: 'views/Home.jsx > bwGoal > no target → null',
    vitest: null,
  },

  // homeView — weekStart 1 (Monday), todayIso is a Monday so wThisWeek counts all that week
  {
    id: 'p31-viewagg-017',
    fn: 'viewAgg.homeView',
    args: [
      {
        ...defaultState,
        weekStart: 1,
        week: { 1: ['rA'], 3: ['rB'], 5: ['rC'] }, // 3 planned days
        bodyweight: [
          { d: '2025-12-31', w: 82.0, t: T_2026_01_01 - 86400000 },
          { d: '2026-01-01', w: 81.5, t: T_2026_01_01 },
        ],
        workouts: [
          { id: 'hw1', d: '2026-01-01', start: T_2026_01_01, vol: 200 }, // 2026-01-01 is Thursday; weekKey(2026-01-01, MONDAY) = '2025-12-29'
          { id: 'hw2', d: '2026-01-12', start: T_2026_01_08 + 4 * 86400000, vol: 300 }, // 2026-01-12 Monday; weekKey = '2026-01-12'
        ],
      },
      '2026-01-12', // todayIso = Monday Jan 12 → weekKey('2026-01-12', 1) = '2026-01-12'
    ],
    from: 'views/Home.jsx:30-58 > homeView > delta, wThisWeek, plannedPerWeek, bwPoints',
  },
];

