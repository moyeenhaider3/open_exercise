// SPDX-License-Identifier: AGPL-3.0-or-later

const CARDIO = '3220';
const LIFT = '0011';
const BW = '0001';

export const cases = [
  // modeOf
  {
    id: 'hist-001',
    fn: 'history.modeOf',
    args: [{ id: CARDIO }],
    from: 'history.test.js > modeOf > falls back to the body part when a plan has no mode',
    vitest: 'cardio',
  },
  {
    id: 'hist-002',
    fn: 'history.modeOf',
    args: [{ id: LIFT }],
    from: 'history.test.js > modeOf > falls back to the body part when a plan has no mode',
    vitest: 'reps',
  },
  {
    id: 'hist-003',
    fn: 'history.modeOf',
    args: [{ id: LIFT, mode: 'time' }],
    from: 'history.test.js > modeOf > lets an explicit mode win over the body part',
    vitest: 'time',
  },
  {
    id: 'hist-004',
    fn: 'history.modeOf',
    args: [{ id: CARDIO, mode: 'reps' }],
    from: 'history.test.js > modeOf > lets an explicit mode win over the body part',
    vitest: 'reps',
  },
  {
    id: 'hist-005',
    fn: 'history.modeOf',
    args: [{ id: LIFT, mode: 'nonsense' }],
    from: 'history.test.js > modeOf > ignores a mode it does not know',
    vitest: 'reps',
  },

  // isTimed
  {
    id: 'hist-006',
    fn: 'history.isTimed',
    args: [{ id: LIFT, mode: 'time' }],
    from: 'history.test.js > modeOf > exposes the timed check',
    vitest: true,
  },
  {
    id: 'hist-007',
    fn: 'history.isTimed',
    args: [{ id: LIFT }],
    from: 'history.test.js > modeOf > exposes the timed check',
    vitest: false,
  },

  // isBw & isPerSide
  {
    id: 'hist-008',
    fn: 'history.isBw',
    args: [{ id: BW }],
    from: 'history.test.js > isBw > detects bodyweight exercises',
    vitest: true,
  },
  {
    id: 'hist-009',
    fn: 'history.isBw',
    args: [{ id: LIFT }],
    from: 'history.test.js > isBw > detects non-bodyweight exercises',
    vitest: false,
  },
  {
    id: 'hist-010',
    fn: 'history.isPerSide',
    args: [{ side: true }],
    from: 'history.test.js > isPerSide > detects per-side target',
    vitest: true,
  },
  {
    id: 'hist-011',
    fn: 'history.isPerSide',
    args: [{}],
    from: 'history.test.js > isPerSide > detects standard target',
    vitest: false,
  },
  {
    id: 'hist-012',
    fn: 'history.sideReps',
    args: [16],
    from: 'history.test.js > sideReps > divides total reps by 2 for per-side',
    vitest: 8,
  },

  // effortOf
  {
    id: 'hist-013',
    fn: 'history.effortOf',
    args: [{ effort: 'rpe' }],
    from: 'history.test.js > effortOf > reads the scale a profile logs',
    vitest: 'rpe',
  },
  {
    id: 'hist-014',
    fn: 'history.effortOf',
    args: [{ effort: 'rir' }],
    from: 'history.test.js > effortOf > reads the scale a profile logs',
    vitest: 'rir',
  },
  {
    id: 'hist-015',
    fn: 'history.effortOf',
    args: [{ effort: 'none' }],
    from: 'history.test.js > effortOf > reads the scale a profile logs',
    vitest: 'none',
  },
  {
    id: 'hist-016',
    fn: 'history.effortOf',
    args: [{}],
    from: 'history.test.js > effortOf > reads the scale a profile logs',
    vitest: 'none',
  },
  {
    id: 'hist-017',
    fn: 'history.effortOf',
    args: [{ showRir: true }],
    from: 'history.test.js > effortOf > keeps the column for a profile still carrying the old showRir flag',
    vitest: 'rir',
  },

  // stepEffort
  {
    id: 'hist-018',
    fn: 'history.stepEffort',
    args: ['rir', null, 1],
    from: 'history.test.js > stepEffort > starts at the bottom of the scale and walks up',
    vitest: 0,
  },
  {
    id: 'hist-019',
    fn: 'history.stepEffort',
    args: ['rpe', null, 1],
    from: 'history.test.js > stepEffort > starts at the bottom of the scale and walks up',
    vitest: 6,
  },
  {
    id: 'hist-020',
    fn: 'history.stepEffort',
    args: ['rir', 0, 1],
    from: 'history.test.js > stepEffort > starts at the bottom of the scale and walks up',
    vitest: 0.5,
  },
  {
    id: 'hist-021',
    fn: 'history.stepEffort',
    args: ['rpe', 6, 1],
    from: 'history.test.js > stepEffort > starts at the bottom of the scale and walks up',
    vitest: 6.5,
  },
  {
    id: 'hist-022',
    fn: 'history.stepEffort',
    args: ['rir', null, -1],
    from: 'history.test.js > stepEffort > leaves an untouched cell unlogged when stepped down',
    vitest: null,
  },

  // workoutVolume
  {
    id: 'hist-023',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              { w: 60, r: 10, done: true },
              { w: 60, r: 10, done: false },
            ],
          },
          { id: LIFT, target: { mode: 'time' }, sets: [{ sec: 60, w: 20, done: true }] },
          { id: CARDIO, sets: [{ min: 20, speed: 9, done: true }] },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > counts reps work and leaves timed/cardio sets out',
    vitest: 600,
  },
  {
    id: 'hist-024',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: LIFT,
            target: { side: true },
            sets: [{ w: 20, r: 16, done: true }],
          },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > needs no per-side case - the logged reps are already both sides',
    vitest: 320,
  },
  {
    id: 'hist-025',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              {
                type: 'dropset',
                w: 100,
                r: 5,
                done: true,
                drops: [
                  { w: 80, r: 5 },
                  { w: 60, r: 5 },
                ],
              },
            ],
          },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > adds drop-set drops on top of the rows main set',
    vitest: 1200,
  },
  {
    id: 'hist-026',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              {
                type: 'restpause',
                w: 60,
                r: 20,
                done: true,
                clusters: [
                  { r: 10, restSec: 15 },
                  { r: 5, restSec: 15 },
                ],
              },
            ],
          },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > counts a rest-pause row once',
    vitest: 1200,
  },
  {
    id: 'hist-027',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              {
                type: 'dropset',
                w: 100,
                r: 5,
                done: false,
                drops: [{ w: 80, r: 5 }],
              },
            ],
          },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > ignores drops/bursts on a row that was never checked off',
    vitest: 0,
  },
  {
    id: 'hist-028',
    fn: 'history.workoutVolume',
    args: [
      {
        entries: [
          {
            id: BW,
            target: { bodyweight: true },
            sets: [{ w: 0, r: 20, done: true }],
          },
        ],
      },
    ],
    from: 'history.test.js > workoutVolume > leaves an unloaded bodyweight set at zero volume',
    vitest: 0,
  },

  // setsDone & workSetsDone
  {
    id: 'hist-029',
    fn: 'history.setsDone',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              { done: true, warmup: true },
              { done: true, phase: 'work' },
              { done: false, phase: 'work' },
            ],
          },
        ],
      },
    ],
    from: 'history.test.js > setsDone > counts all done sets including warmup',
    vitest: 2,
  },
  {
    id: 'hist-030',
    fn: 'history.workSetsDone',
    args: [
      {
        entries: [
          {
            id: LIFT,
            sets: [
              { done: true, warmup: true },
              { done: true, phase: 'work' },
              { done: false, phase: 'work' },
            ],
          },
        ],
      },
    ],
    from: 'history.test.js > workSetsDone > counts only done work sets',
    vitest: 1,
  },

  // bestWeightForEntry
  {
    id: 'hist-031',
    fn: 'history.bestWeightForEntry',
    args: [
      {
        id: LIFT,
        sets: [
          { w: 50, done: true },
          { w: 60, done: true },
          { w: 70, done: false },
        ],
      },
    ],
    from: 'history.test.js > bestWeightForEntry > finds highest weight among done sets',
    vitest: 60,
  },

  // cascadeWeight
  {
    id: 'hist-032',
    fn: 'history.cascadeWeight',
    args: [
      [
        { w: 50, done: false },
        { w: 50, done: false },
        { w: 50, done: false },
      ],
      0,
      60,
    ],
    from: 'history.test.js > cascadeWeight > cascades new weight to all subsequent undone sets',
  },
];
