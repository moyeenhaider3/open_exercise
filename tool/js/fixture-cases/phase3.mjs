// SPDX-License-Identifier: AGPL-3.0-or-later

const finishState = {
  customEx: [],
  exWeights: { '0025': { w: 90, d: '2026-09-20' } },
  workouts: [],
  active: {
    id: 'w_active_1',
    d: '2026-09-28',
    start: 1700000000000,
    name: 'Workout A',
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
  // Muscles
  {
    id: 'p3-muscles-001',
    fn: 'muscles.inMuscleOrder',
    args: [['triceps', 'chest']],
    from: 'muscles.test.js > inMuscleOrder > sorts muscles into anatomical order',
    vitest: ['chest', 'triceps'],
  },
  {
    id: 'p3-muscles-002',
    fn: 'muscles.hasExplicitMuscleMetadata',
    args: [{ muscleGroups: ['chest'] }],
    from: 'muscles.test.js > hasExplicitMuscleMetadata > true when muscleGroups is present',
    vitest: true,
  },
  {
    id: 'p3-muscles-003',
    fn: 'muscles.hasExplicitMuscleMetadata',
    args: [{ bp: 'chest' }],
    from: 'muscles.test.js > hasExplicitMuscleMetadata > false for bodypart-only exercise',
    vitest: false,
  },
  {
    id: 'p3-muscles-004',
    fn: 'muscles.normalizeMuscleGroups',
    args: [{ muscleGroups: ['chest', 'pectorals', 'triceps'] }],
    from: 'muscles.test.js > normalizeMuscleGroups > maps aliases to canonical groups',
    vitest: ['chest', 'triceps'],
  },
  {
    id: 'p3-muscles-005',
    fn: 'muscles.exerciseMuscleSnapshot',
    args: [{ n: 'Bench Press', bp: 'chest', tg: 'pectorals' }],
    from: 'muscles.test.js > exerciseMuscleSnapshot > extracts muscle weights snapshot',
  },

  // Effort
  {
    id: 'p3-effort-001',
    fn: 'effort.rirOf',
    args: [{ rir: 2 }],
    from: 'effort.test.js > rirOf > reads RIR straight',
    vitest: 2,
  },
  {
    id: 'p3-effort-002',
    fn: 'effort.rirOf',
    args: [{ rpe: 8 }],
    from: 'effort.test.js > rirOf > RPE 8 mirrors to RIR 2',
    vitest: 2,
  },
  {
    id: 'p3-effort-003',
    fn: 'effort.rirOf',
    args: [{}],
    from: 'effort.test.js > rirOf > unrated set is null',
    vitest: null,
  },
  {
    id: 'p3-effort-004',
    fn: 'effort.toScale',
    args: ['rpe', 2],
    from: 'effort.test.js > toScale > converts RIR 2 to RPE 8',
    vitest: 8,
  },
  {
    id: 'p3-effort-005',
    fn: 'effort.toScale',
    args: ['rir', 2],
    from: 'effort.test.js > toScale > identity for RIR',
    vitest: 2,
  },
  {
    id: 'p3-effort-006',
    fn: 'effort.effortColor',
    args: [0],
    from: 'effort.test.js > effortColor > RIR 0 failure is purple',
    vitest: 'var(--purple)',
  },
  {
    id: 'p3-effort-007',
    fn: 'effort.effortColor',
    args: [2],
    from: 'effort.test.js > effortColor > RIR 2 is yellow',
    vitest: 'var(--yellow)',
  },
  {
    id: 'p3-effort-008',
    fn: 'effort.effortColor',
    args: [null],
    from: 'effort.test.js > effortColor > unrated has no color',
    vitest: null,
  },

  // Starter
  {
    id: 'p3-starter-001',
    fn: 'starter.starterPlanOptions',
    args: [],
    from: 'starter.test.js > starterPlanOptions > lists 4 starter plans with day counts',
    vitest: [
      { id: 'ppl', days: 3 },
      { id: 'upper-lower', days: 4 },
      { id: 'full-body', days: 3 },
      { id: '5x5', days: 3 },
    ],
  },
  {
    id: 'p3-starter-002',
    fn: 'starter.starterPlanDays',
    args: ['ppl'],
    from: 'starter.test.js > starterPlanDays > PPL runs Mon/Wed/Fri (1, 3, 5)',
    vitest: [1, 3, 5],
  },
  {
    id: 'p3-starter-003',
    fn: 'starter.starterPlanDays',
    args: ['unknown'],
    from: 'starter.test.js > starterPlanDays > unknown plan id is null',
    vitest: null,
  },
  {
    id: 'p3-starter-004',
    fn: 'starter.buildStarterPlan',
    args: ['unknown'],
    from: 'starter.test.js > buildStarterPlan > unknown plan id is null',
    vitest: null,
  },

  // Exercise History
  {
    id: 'p3-history-001',
    fn: 'exerciseHistory.exerciseHistory',
    args: [{ workouts: [] }, '0025'],
    from: 'exercise-history.test.js > exerciseHistory > empty history defaults',
    vitest: {
      mode: 'reps',
      metric: 'weight',
      best: 0,
      prId: null,
      total: 0,
      sessions: [],
      points: [],
      e1rmPoints: [],
    },
  },

  // Rep Range
  {
    id: 'p3-reprange-001',
    fn: 'repRange.normalizeRepRange',
    args: [12, 8],
    from: 'rep-range.test.js > normalizeRepRange > keeps valid bounds',
    vitest: { reps: 12, repsMin: 8 },
  },
  {
    id: 'p3-reprange-002',
    fn: 'repRange.normalizeRepRange',
    args: [8, 8],
    from: 'rep-range.test.js > normalizeRepRange > raises upper bound when lower equals it',
    vitest: { reps: 9, repsMin: 8 },
  },
  {
    id: 'p3-reprange-003',
    fn: 'repRange.normalizeRepRange',
    args: [13, 7, 2],
    from: 'rep-range.test.js > normalizeRepRange > aligns to stride 2',
    vitest: { reps: 14, repsMin: 8 },
  },

  // Progression Copy
  {
    id: 'p3-progcopy-001',
    fn: 'progressionCopy.progressionGuidance',
    args: [{ policy: 'linear', kind: 'up', weight: 62.5, why: ['Every rep last time — {0} {1} more.', 2.5, 'kg'] }],
    from: 'progression-copy.test.js > progressionGuidance > labels linear progression',
    vitest: {
      policyLabel: 'Linear progression',
      why: ['Every rep last time — {0} {1} more.', 2.5, 'kg'],
    },
  },
  {
    id: 'p3-progcopy-002',
    fn: 'progressionCopy.progressionGuidance',
    args: [{ policy: 'off', kind: 'off' }],
    from: 'progression-copy.test.js > progressionGuidance > off policy has no guidance',
    vitest: null,
  },

  // Finish Workout
  {
    id: 'p3-finish-001',
    fn: 'finish.completeWorkout',
    args: [finishState, 1700003600000],
    from: 'sheets.jsx > doFinishWorkout > non-backfill workout finish',
    vitest: {
      workout: {
        id: 'w_active_1',
        d: '2026-09-28',
        start: 1700000000000,
        end: 1700003600000,
        routineIds: [],
        routineId: null,
        name: 'Workout A',
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
        prs: ['0025'],
        vol: 500,
      },
      prs: ['0025'],
      e1prs: [],
      exWeights: {
        '0025': {
          w: 100,
          d: '2026-09-28',
        },
      },
      past: false,
      replaceId: null,
    },
  },
];
