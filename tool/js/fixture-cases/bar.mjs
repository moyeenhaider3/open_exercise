// SPDX-License-Identifier: AGPL-3.0-or-later

const smith = { id: 'sm', eq: 'smith machine' };
const bb = { id: 'bb', eq: 'barbell' };
const ez = { id: 'ez', eq: 'ez barbell' };
const dumbbell = { id: 'db', eq: 'dumbbell' };

const S_kg = { unit: 'kg', barWeights: {} };
const S_lb = { unit: 'lb', barWeights: {} };
const S_smith0 = { unit: 'kg', barWeights: { sm: 0 } };
const S_smith15 = { unit: 'kg', barWeights: { sm: 15 } };
const S_ezOverride = { unit: 'kg', barWeights: { ez: 7.5 } };

export const cases = [
  {
    id: 'bar-001',
    fn: 'bar.usesBar',
    args: [smith],
    from: 'bar.test.js > bar equipment > usesBar answers for ids and exercise objects alike',
    vitest: true,
  },
  {
    id: 'bar-002',
    fn: 'bar.usesBar',
    args: [dumbbell],
    from: 'bar.test.js > bar equipment > usesBar answers for ids and exercise objects alike',
    vitest: false,
  },
  {
    id: 'bar-003',
    fn: 'bar.usesBar',
    args: [null],
    from: 'bar.test.js > bar equipment > usesBar answers for ids and exercise objects alike',
    vitest: false,
  },
  {
    id: 'bar-004',
    fn: 'bar.defaultBarWeight',
    args: ['ez barbell', 'kg'],
    from: 'bar.test.js > per-unit defaults > every bar type has a default in both units',
    vitest: 10,
  },
  {
    id: 'bar-005',
    fn: 'bar.defaultBarWeight',
    args: ['ez barbell', 'lb'],
    from: 'bar.test.js > per-unit defaults > every bar type has a default in both units',
    vitest: 25,
  },
  {
    id: 'bar-006',
    fn: 'bar.defaultBarWeight',
    args: ['olympic barbell', 'kg'],
    from: 'bar.test.js > per-unit defaults > every bar type has a default in both units',
    vitest: 20,
  },
  {
    id: 'bar-007',
    fn: 'bar.defaultBarWeight',
    args: ['barbell', 'lb'],
    from: 'bar.test.js > per-unit defaults > every bar type has a default in both units',
    vitest: 45,
  },
  {
    id: 'bar-008',
    fn: 'bar.defaultBarWeight',
    args: ['dumbbell', 'kg'],
    from: 'bar.test.js > per-unit defaults > every bar type has a default in both units',
    vitest: null,
  },
  {
    id: 'bar-009',
    fn: 'bar.isNoBar',
    args: [S_smith0, 'sm'],
    from: 'bar-nobar.test.js > no bar at all > tells "no bar" apart from "nothing set"',
    vitest: true,
  },
  {
    id: 'bar-010',
    fn: 'bar.isNoBar',
    args: [S_smith15, 'sm'],
    from: 'bar-nobar.test.js > no bar at all > tells "no bar" apart from "nothing set"',
    vitest: false,
  },
  {
    id: 'bar-011',
    fn: 'bar.hasBarOverride',
    args: [S_smith0, 'sm'],
    from: 'bar-nobar.test.js > no bar at all > tells "no bar" apart from "nothing set"',
    vitest: true,
  },
  {
    id: 'bar-012',
    fn: 'bar.hasBarOverride',
    args: [S_kg, 'sm'],
    from: 'bar-nobar.test.js > no bar at all > tells "no bar" apart from "nothing set"',
    vitest: false,
  },
  {
    id: 'bar-013',
    fn: 'bar.barWeightFor',
    args: [S_smith0, smith],
    from: 'bar-nobar.test.js > no bar at all > keeps a stored 0 instead of falling back to the bar type default',
    vitest: 0,
  },
  {
    id: 'bar-014',
    fn: 'bar.barWeightFor',
    args: [S_kg, smith],
    from: 'bar-nobar.test.js > no bar at all > keeps a stored 0 instead of falling back to the bar type default',
    vitest: 9,
  },
  {
    id: 'bar-015',
    fn: 'bar.barWeightFor',
    args: [S_lb, bb],
    from: 'bar.test.js > barWeightFor > falls back to the equipment default in the profile unit',
    vitest: 45,
  },
  {
    id: 'bar-016',
    fn: 'bar.barWeightFor',
    args: [S_ezOverride, ez],
    from: 'bar.test.js > barWeightFor > an explicit override wins over the default',
    vitest: 7.5,
  },
  {
    id: 'bar-017',
    fn: 'bar.barWeightFor',
    args: [S_kg, dumbbell],
    from: 'bar.test.js > barWeightFor > is null for anything without a bar',
    vitest: null,
  },
  {
    id: 'bar-018',
    fn: 'bar.plateSplit',
    args: [100, 20],
    from: 'bar.test.js > plateSplit > splits what is beyond the bar evenly per side',
    vitest: 40,
  },
  {
    id: 'bar-019',
    fn: 'bar.plateSplit',
    args: [62.5, 20],
    from: 'bar.test.js > plateSplit > splits what is beyond the bar evenly per side',
    vitest: 21.25,
  },
  {
    id: 'bar-020',
    fn: 'bar.plateSplit',
    args: [100, 0],
    from: 'bar-nobar.test.js > no bar at all > counts every plate when there is no bar',
    vitest: 50,
  },
  {
    id: 'bar-021',
    fn: 'bar.plateSplit',
    args: [20, 20],
    from: 'bar.test.js > plateSplit > is null when there is nothing sensible to show',
    vitest: null,
  },
  {
    id: 'bar-022',
    fn: 'bar.plateSplit',
    args: [15, 20],
    from: 'bar.test.js > plateSplit > is null when there is nothing sensible to show',
    vitest: null,
  },
];
