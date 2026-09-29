// SPDX-License-Identifier: AGPL-3.0-or-later
/**
 * Transcribed from ../openGym/frontend/src/sheets.jsx doFinishWorkout lines 2188-2227.
 * Provides both live and backfill branches of workout completion so identical numbers
 * (prs, e1prs, volume, exWeights) are calculated in the JS runtime.
 */

import { EXIDX, registerCustom, betterWeight, beatsWeight } from '../../../third_party/opengym/lib/exercises.js';
import { bestWeightFor, bestWeightForEntry, workoutVolume } from '../../../third_party/opengym/lib/history.js';
import { exerciseMuscleSnapshot } from '../../../third_party/opengym/lib/muscles.js';
import { is1RMRecord } from '../../../third_party/opengym/lib/onerm.js';
import { buildCompletedWorkout } from '../../../third_party/opengym/lib/finish-workout.js';
import { isWarmupRow } from '../../../third_party/opengym/lib/workout-model.js';
import { backfillEnd } from '../../../third_party/opengym/lib/backfill.js';

export function completeWorkout(st, end) {
  const A = st && st.active;
  if (!A) {
    throw new Error('completeWorkout: no active workout in state');
  }
  const past = !!A.backfill;

  registerCustom(st.customEx || []);

  const prs = [];
  const e1prs = [];

  if (!past) {
    (A.entries || []).forEach(e => {
      const loads = (e.sets || [])
        .filter(s => s.done && !isWarmupRow(s))
        .map(s => s.w)
        .filter(w => w > 0);
      const mx = loads.length ? loads.reduce((a, b) => betterWeight(e.id, a, b)) : 0;
      if (beatsWeight(e.id, mx, bestWeightFor(st, e.id))) {
        prs.push(e.id);
      }
      const rec = is1RMRecord(st, e.id, e);
      if (rec && !prs.includes(e.id)) {
        e1prs.push({ id: e.id, ...rec });
      }
    });
  }

  const snapshotFor = e => (EXIDX[e.id]?.custom ? exerciseMuscleSnapshot(EXIDX[e.id]) : null);
  const w = buildCompletedWorkout(A, {
    end: past ? backfillEnd(A) : (end != null ? end : Date.now()),
    prs,
    snapshotFor,
  });
  w.vol = workoutVolume(w);

  // Compute next exWeights without mutating st.exWeights directly
  const exWeights = Object.assign({}, st.exWeights || {});
  if (!past) {
    (w.entries || []).forEach(e => {
      const mx = bestWeightForEntry(e);
      if (mx > 0 && beatsWeight(e.id, mx, (exWeights[e.id] || {}).w || 0)) {
        exWeights[e.id] = { w: mx, d: w.d };
      }
    });
  }

  return {
    workout: w,
    prs,
    e1prs,
    exWeights,
    past,
    replaceId: past ? (A.backfill.replaceId || null) : null,
  };
}

