// SPDX-License-Identifier: AGPL-3.0-or-later

const LIFT = '0011';
const HEAVY = '1512';
const CARDIO = '3220';

const hist = (id, rows, target) => ({
  unit: 'kg',
  workouts: rows.map((row, i) => ({
    d: '2026-01-0' + (i + 1),
    entries: [
      {
        id,
        target: target || { sets: 3, reps: 5, weight: row[0] },
        sets: row
          .slice(1)
          .map(r => (r === null ? { w: row[0], r: 0, done: false } : { w: row[0], r, done: true })),
      },
    ],
  })),
});

const cfg = { id: LIFT, sets: 3, reps: 5, weight: 60, prog: 'linear' };

export const cases = [
  // readSession
  {
    id: 'prog-001',
    fn: 'progression.readSession',
    args: [
      {
        id: LIFT,
        target: { sets: 3, reps: 5 },
        sets: [
          { w: 60, r: 5, done: true },
          { w: 60, r: 5, done: true },
          { w: 60, r: 6, done: true },
        ],
      },
    ],
    from: 'progression.test.js > readSession > counts a session where every set made its reps as a hit',
  },
  {
    id: 'prog-002',
    fn: 'progression.readSession',
    args: [
      {
        id: LIFT,
        target: { sets: 3, reps: 5 },
        sets: [
          { w: 60, r: 5, done: true },
          { w: 60, r: 5, done: true },
          { w: 60, r: 3, done: true },
        ],
      },
    ],
    from: 'progression.test.js > readSession > counts short reps as a miss even when the set was checked off',
  },
  {
    id: 'prog-003',
    fn: 'progression.readSession',
    args: [
      {
        id: LIFT,
        target: { sets: 3, reps: 5 },
        sets: [
          { w: 60, r: 5, done: true },
          { w: 60, r: 5, done: true },
          { w: 60, r: 0, done: false },
        ],
      },
    ],
    from: 'progression.test.js > readSession > counts an unchecked set as a miss',
  },
  {
    id: 'prog-004',
    fn: 'progression.readSession',
    args: [
      {
        id: LIFT,
        target: { sets: 2, sec: 45, mode: 'time' },
        sets: [
          { sec: 45, w: 0, done: true },
          { sec: 50, w: 0, done: true },
        ],
      },
    ],
    from: 'progression.test.js > readSession > reads a timed session by the hold, not by reps',
  },

  // stallCount
  {
    id: 'prog-005',
    fn: 'progression.stallCount',
    args: [[{ ok: true }, { ok: true }]],
    from: 'progression.test.js > stallCount > counts consecutive misses back from the most recent session',
    vitest: 0,
  },
  {
    id: 'prog-006',
    fn: 'progression.stallCount',
    args: [[{ ok: true }, { ok: false }]],
    from: 'progression.test.js > stallCount > counts consecutive misses back from the most recent session',
    vitest: 1,
  },
  {
    id: 'prog-007',
    fn: 'progression.stallCount',
    args: [[{ ok: false }, { ok: false }, { ok: false }]],
    from: 'progression.test.js > stallCount > counts consecutive misses back from the most recent session',
    vitest: 3,
  },
  {
    id: 'prog-008',
    fn: 'progression.stallCount',
    args: [[]],
    from: 'progression.test.js > stallCount > counts consecutive misses back from the most recent session',
    vitest: 0,
  },

  // policyFor
  {
    id: 'prog-009',
    fn: 'progression.policyFor',
    args: [{ id: LIFT }, null, 'reps'],
    from: 'progression.test.js > policyFor > keeps the app long-standing behaviour as the default for reps work',
    vitest: 'linear',
  },
  {
    id: 'prog-010',
    fn: 'progression.policyFor',
    args: [{ id: LIFT, mode: 'time' }, null, 'time'],
    from: 'progression.test.js > policyFor > leaves timed and cardio work alone unless asked',
    vitest: 'off',
  },
  {
    id: 'prog-011',
    fn: 'progression.policyFor',
    args: [{ id: CARDIO }, null, 'cardio'],
    from: 'progression.test.js > policyFor > leaves timed and cardio work alone unless asked',
    vitest: 'off',
  },
  {
    id: 'prog-012',
    fn: 'progression.policyFor',
    args: [{ id: LIFT }, { prog: 'greyskull' }, 'reps'],
    from: 'progression.test.js > policyFor > lets the exercise override the routine, and the routine override the default',
    vitest: 'greyskull',
  },
  {
    id: 'prog-013',
    fn: 'progression.policyFor',
    args: [{ id: LIFT, prog: 'double' }, { prog: 'greyskull' }, 'reps'],
    from: 'progression.test.js > policyFor > lets the exercise override the routine, and the routine override the default',
    vitest: 'double',
  },

  // defaultIncrement
  {
    id: 'prog-014',
    fn: 'progression.defaultIncrement',
    args: [LIFT, 'kg'],
    from: 'progression.test.js > defaultIncrement > gives lower-body lifts the bigger jump',
    vitest: 2.5,
  },
  {
    id: 'prog-015',
    fn: 'progression.defaultIncrement',
    args: [HEAVY, 'kg'],
    from: 'progression.test.js > defaultIncrement > gives lower-body lifts the bigger jump',
    vitest: 5,
  },
  {
    id: 'prog-016',
    fn: 'progression.defaultIncrement',
    args: [LIFT, 'lb'],
    from: 'progression.test.js > defaultIncrement > scales to pounds',
    vitest: 5,
  },
  {
    id: 'prog-017',
    fn: 'progression.defaultIncrement',
    args: [HEAVY, 'lb'],
    from: 'progression.test.js > defaultIncrement > scales to pounds',
    vitest: 10,
  },

  // weightIncrement
  {
    id: 'prog-018',
    fn: 'progression.weightIncrement',
    args: [{ id: LIFT, inc: 1 }, 'kg'],
    from: 'progression.test.js > weightIncrement > uses a positive exercise override and otherwise the exercise/unit default',
    vitest: 1,
  },
  {
    id: 'prog-019',
    fn: 'progression.weightIncrement',
    args: [{ id: LIFT }, 'kg'],
    from: 'progression.test.js > weightIncrement > uses a positive exercise override and otherwise the exercise/unit default',
    vitest: 2.5,
  },
  {
    id: 'prog-020',
    fn: 'progression.weightIncrement',
    args: [{ id: HEAVY, inc: 0 }, 'kg'],
    from: 'progression.test.js > weightIncrement > uses a positive exercise override and otherwise the exercise/unit default',
    vitest: 5,
  },

  // Epley & deload
  {
    id: 'prog-021',
    fn: 'progression.epley1RM',
    args: [60, 8],
    from: 'progression.test.js > Epley deload helpers > maps a prescribed target pair to the requested Epley 1RM factor',
    vitest: 76,
  },
  {
    id: 'prog-022',
    fn: 'progression.deloadTarget1RM',
    args: [60, 8],
    from: 'progression.test.js > Epley deload helpers > maps a prescribed target pair to the requested Epley 1RM factor',
    vitest: 68.4,
  },
  {
    id: 'prog-023',
    fn: 'progression.deloadTarget1RM',
    args: [60, 8, 0.8],
    from: 'progression.test.js > Epley deload helpers > maps a prescribed target pair to the requested Epley 1RM factor',
    vitest: 60.8,
  },
  {
    id: 'prog-024',
    fn: 'progression.isValidDeloadFactor',
    args: [0.9],
    from: 'progression.js > isValidDeloadFactor > valid factor 0.9',
    vitest: true,
  },
  {
    id: 'prog-025',
    fn: 'progression.isValidDeloadFactor',
    args: [0.1],
    from: 'progression.js > isValidDeloadFactor > invalid factor 0.1 below min',
    vitest: false,
  },
  {
    id: 'prog-026',
    fn: 'progression.deloadFactorOf',
    args: [{}],
    from: 'progression.test.js > Epley deload helpers > uses the configured factor and keeps the ratio backward-compatible',
    vitest: 0.9,
  },
  {
    id: 'prog-027',
    fn: 'progression.snapWeight',
    args: [60.1, 2.5],
    from: 'progression.js > snapWeight > snaps to nearest step',
    vitest: 60,
  },
  {
    id: 'prog-028',
    fn: 'progression.addStep',
    args: [60, 2.5],
    from: 'progression.js > addStep > adds step to weight',
    vitest: 62.5,
  },
  {
    id: 'prog-029',
    fn: 'progression.stepWeight',
    args: [60, 1, 2.5],
    from: 'progression.js > stepWeight > steps weight by delta',
    vitest: 63,
  },
  {
    id: 'prog-030',
    fn: 'progression.deloadTo',
    args: [100, 2.5, 0.9],
    from: 'progression.js > deloadTo > deloads 100 kg to 90 kg',
    vitest: 90,
  },
  {
    id: 'prog-031',
    fn: 'progression.deloadTo',
    args: [60, 2.5, 0.9],
    from: 'progression.js > deloadTo > deloads 60 kg to 55 kg',
    vitest: 55,
  },

  // nextPrescription
  {
    id: 'prog-032',
    fn: 'progression.nextPrescription',
    args: [{ unit: 'kg', workouts: [] }, cfg],
    from: 'progression.test.js > linear progression > says nothing useful before there is any history',
  },
  {
    id: 'prog-033',
    fn: 'progression.nextPrescription',
    args: [hist(LIFT, [[60, 5, 5, 5]]), cfg],
    from: 'progression.test.js > linear progression > adds the increment after a clean session',
  },
  {
    id: 'prog-034',
    fn: 'progression.nextPrescription',
    args: [hist(LIFT, [[60, 5, 5, 3]]), cfg],
    from: 'progression.test.js > linear progression > repeats the weight after a miss instead of advancing',
  },
  {
    id: 'prog-035',
    fn: 'progression.nextPrescription',
    args: [hist(LIFT, [[60, 5, 5, 3], [60, 5, 4, 4], [60, 5, 5, 4]]), cfg],
    from: 'progression.test.js > linear progression > deloads after three misses in a row, onto a loadable weight',
  },
];
