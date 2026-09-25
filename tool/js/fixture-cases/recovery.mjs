// SPDX-License-Identifier: AGPL-3.0-or-later

import { MUSCLES } from '../../../third_party/opengym/lib/muscles.js';

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const NOW = Date.UTC(2026, 0, 1, 12); // Fixed deterministic epoch ms

const SINGLE_ID = '1368'; // bicep curl

const doneWorkoutAt = (id, start, count = 1) => ({
  d: new Date(start).toISOString(),
  start,
  entries: [{ id, sets: Array.from({ length: count }, () => ({ done: true, w: 80, r: 8 })) }],
});

const zeroFatigue = Object.fromEntries(MUSCLES.map(m => [m, 0]));
const floorStrength = Object.fromEntries(MUSCLES.map(m => [m, 0.5]));

export const cases = [
  // halfLifeDecay
  {
    id: 'recovery-001',
    fn: 'recovery.halfLifeDecay',
    args: [36 * HOUR, 36 * HOUR],
    from: 'recovery.test.js > recovery constants > exports the pinned windows, half-lives, floor, and state labels',
    vitest: 0.5,
  },
  {
    id: 'recovery-002',
    fn: 'recovery.halfLifeDecay',
    args: [0, 36 * HOUR],
    from: 'recovery.test.js > recovery constants > zero age has full decay factor of 1',
    vitest: 1,
  },
  {
    id: 'recovery-003',
    fn: 'recovery.halfLifeDecay',
    args: [72 * HOUR, 36 * HOUR],
    from: 'recovery.test.js > recovery constants > two half-lives decay to 0.25',
    vitest: 0.25,
  },

  // Empty history defaults
  {
    id: 'recovery-004',
    fn: 'recovery.fatigueOf',
    args: [[], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > returns every muscle, ready/floor defaults, and hook defaults for empty history',
    vitest: zeroFatigue,
  },
  {
    id: 'recovery-005',
    fn: 'recovery.strengthOf',
    args: [[], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > returns every muscle, ready/floor defaults, and hook defaults for empty history',
    vitest: floorStrength,
  },
  {
    id: 'recovery-006',
    fn: 'recovery.fatiguedMuscles',
    args: [[], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > returns every muscle, ready/floor defaults, and hook defaults for empty history',
    vitest: [],
  },
  {
    id: 'recovery-007',
    fn: 'recovery.detrainedMuscles',
    args: [[], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > returns every muscle, ready/floor defaults, and hook defaults for empty history',
    vitest: MUSCLES,
  },

  // Fresh workout stimulus
  {
    id: 'recovery-008',
    fn: 'recovery.fatigueOf',
    args: [[doneWorkoutAt(SINGLE_ID, NOW)], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > applies one completed set to each of the exercise muscle weights',
  },
  {
    id: 'recovery-009',
    fn: 'recovery.strengthOf',
    args: [[doneWorkoutAt(SINGLE_ID, NOW)], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > applies one completed set to each of the exercise muscle weights',
  },

  // Decayed stimulus
  {
    id: 'recovery-010',
    fn: 'recovery.fatigueOf',
    args: [[doneWorkoutAt(SINGLE_ID, NOW - 36 * HOUR)], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > decays fatigue over time',
  },
  {
    id: 'recovery-011',
    fn: 'recovery.strengthOf',
    args: [[doneWorkoutAt(SINGLE_ID, NOW - 14 * DAY)], NOW],
    from: 'recovery.test.js > fatigueOf and strengthOf > preserves full strength within strength full window',
  },

  // Active muscle sets
  {
    id: 'recovery-012',
    fn: 'recovery.fatiguedMuscles',
    args: [[doneWorkoutAt(SINGLE_ID, NOW, 5)], NOW],
    from: 'recovery.test.js > fatiguedMuscles > identifies muscles above fatigue threshold',
  },
  {
    id: 'recovery-013',
    fn: 'recovery.detrainedMuscles',
    args: [[doneWorkoutAt(SINGLE_ID, NOW)], NOW],
    from: 'recovery.test.js > detrainedMuscles > identifies muscles without recent stimulus',
  },
  {
    id: 'recovery-014',
    fn: 'recovery.fatigueOf',
    args: [
      [
        {
          d: new Date(NOW).toISOString(),
          start: NOW,
          entries: [
            {
              id: SINGLE_ID,
              sets: [
                { done: true, w: 20, r: 8, warmup: true },
                { done: true, w: 80, r: 8 },
              ],
            },
          ],
        },
      ],
      NOW,
    ],
    from: 'recovery.test.js > fatigueOf > ignores warmup sets in volume calculation',
  },
];
