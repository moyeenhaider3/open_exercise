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
];
