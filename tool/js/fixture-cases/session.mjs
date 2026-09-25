// SPDX-License-Identifier: AGPL-3.0-or-later

const st = {
  unit: 'kg',
  workouts: [],
  exWeights: {},
  routines: [
    {
      id: 'r1',
      name: 'Strength',
      prog: 'off',
      ex: [
        { id: '0025', sets: 3, reps: 5, weight: 60 },
        { id: '0031', sets: 3, reps: 8, weight: 40 },
      ],
    },
    {
      id: 'r2',
      name: 'Core',
      prog: 'off',
      ex: [{ id: '0047', sets: 3, reps: 12, weight: 0 }],
    },
    {
      id: 'rehab',
      name: 'Rehab',
      excludeFromProgression: true,
      ex: [{ id: '0050', sets: 2, reps: 15, weight: 5 }],
    },
  ],
};

export const cases = [
  {
    id: 'session-001',
    fn: 'sessionStart.buildSessionEntries',
    args: [st, st.routines[0]],
    from: 'session-start.test.js > buildSessionEntries > seeds initial entries from routine',
  },
  {
    id: 'session-002',
    fn: 'sessionStart.buildSessionEntries',
    args: [st, st.routines[2]],
    from: 'session-start.test.js > buildSessionEntries > carries excludeFromProgression as noProg: true',
  },
  {
    id: 'session-003',
    fn: 'sessionMerge.buildCombinedEntries',
    args: [st, ['r1', 'r2']],
    from: 'session-merge.test.js > buildCombinedEntries > concatenates each routine entries in list order, stamping rid on every one',
  },
  {
    id: 'session-004',
    fn: 'sessionMerge.buildCombinedEntries',
    args: [st, ['r1', 'gone', 'r1', 'r2']],
    from: 'session-merge.test.js > buildCombinedEntries > de-dupes a repeated id (first wins) and drops an id with no matching routine',
  },
  {
    id: 'session-005',
    fn: 'sessionMerge.deriveSessionName',
    args: [[]],
    from: 'session-merge.test.js > deriveSessionName > is null for an empty list',
    vitest: null,
  },
  {
    id: 'session-006',
    fn: 'sessionMerge.deriveSessionName',
    args: [['Rehab']],
    from: 'session-merge.test.js > deriveSessionName > joins 1-3 names with " + "',
    vitest: 'Rehab',
  },
  {
    id: 'session-007',
    fn: 'sessionMerge.deriveSessionName',
    args: [['Rehab', 'Core']],
    from: 'session-merge.test.js > deriveSessionName > joins 1-3 names with " + "',
    vitest: 'Rehab + Core',
  },
  {
    id: 'session-008',
    fn: 'sessionMerge.deriveSessionName',
    args: [['A', 'B', 'C']],
    from: 'session-merge.test.js > deriveSessionName > joins 1-3 names with " + "',
    vitest: 'A + B + C',
  },
  {
    id: 'session-009',
    fn: 'sessionMerge.deriveSessionName',
    args: [['A', 'B', 'C', 'D']],
    from: 'session-merge.test.js > deriveSessionName > collapses 4+ to "A + B + N more"',
    vitest: 'A + B + 2 more',
  },
  {
    id: 'session-010',
    fn: 'sessionMerge.deriveSessionName',
    args: [['A', 'B', 'C', 'D', 'E']],
    from: 'session-merge.test.js > deriveSessionName > collapses 4+ to "A + B + N more"',
    vitest: 'A + B + 3 more',
  },
];
