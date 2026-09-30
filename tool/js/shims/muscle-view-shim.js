// SPDX-License-Identifier: AGPL-3.0-or-later
/**
 * Transcribed from openGym views/components so the numbers these screens print run in the JS
 * engine (JS-04). Each export cites its source lines; logic is copied, not re-derived.
 *
 * Imports are restricted to third_party/opengym/lib/ so no UI/i18n code is pulled in.
 */

import { MUSCLES, loadOfWorkouts, muscleBalanceWindow, rankOf, levelsOf, musclesOf } from '../../../third_party/opengym/lib/muscles.js';
import { fatigueOf, strengthOf, STRENGTH_FLOOR, LB_TO_KG } from '../../../third_party/opengym/lib/recovery.js';
import { fatigueStateOf } from '../../../third_party/opengym/lib/recovery-view.js';
import { strengthExerciseRowsForMuscle } from '../../../third_party/opengym/lib/strength-exercises.js';
import { isHardSet } from '../../../third_party/opengym/lib/effort.js';
import { isWarmupRow } from '../../../third_party/opengym/lib/workout-model.js';
import { EXIDX, registerCustom, allExercises } from '../../../third_party/opengym/lib/exercises.js';
import { weekStartOf } from '../../../third_party/opengym/lib/format.js';

// ---------------------------------------------------------------------------
// Constants — Stats.jsx lines 44-58
// ---------------------------------------------------------------------------

export const FATIGUE_LEVELS = [
  { at: 0, level: 0 },
  { at: 0.15, level: 1 },
  { at: 0.25, level: 2 },
  { at: 0.4, level: 3 },
  { at: 0.55, level: 4, exclusive: true },
];

export const STRENGTH_LEVELS = [
  { at: STRENGTH_FLOOR, level: 0 },
  { at: 0.625, level: 1 },
  { at: 0.75, level: 2 },
  { at: 0.875, level: 3 },
  { at: 1, level: 4 },
];

// ---------------------------------------------------------------------------
// Private Helpers — Stats.jsx lines 28-42, 72-74, 107-113
// ---------------------------------------------------------------------------

function bodyweightKgOf(S) {
  const entries = S?.bodyweight || [];
  if (!entries.length) return null;
  const sorted = entries.slice().sort((a, b) => String(a.d).localeCompare(String(b.d)));
  const last = sorted.length ? sorted[sorted.length - 1] : null;
  if (!last || !(last.w > 0)) return null;
  return S.unit === 'lb' ? last.w * LB_TO_KG : last.w;
}

function latestMuscleTraining(workouts) {
  const latest = {};
  for (const workout of workouts || []) {
    const timestamp = Number(workout?.start || new Date(workout?.d).getTime());
    if (!Number.isFinite(timestamp)) continue;
    for (const entry of workout.entries || []) {
      if (!(entry.sets || []).some(set => set?.done === true && !isWarmupRow(set))) continue;
      const exercise = EXIDX[entry.id] || entry.exercise || entry;
      for (const slug of Object.keys(musclesOf(exercise))) {
        if (latest[slug] == null || timestamp > latest[slug]) latest[slug] = timestamp;
      }
    }
  }
  return latest;
}

function weeksSinceTraining(now, lastTrained) {
  return Math.max(0, Math.floor((now - lastTrained) / 86400000 / 7));
}

// ---------------------------------------------------------------------------
// Public Exports — Stats.jsx & MuscleExplorer.jsx
// ---------------------------------------------------------------------------

/**
 * Muscle balance numbers for the given window and hard-set toggle.
 * Source: openGym frontend/src/views/Stats.jsx lines 124-143.
 */
export function muscleBalance(S, win, hard, nowMs, todayIso) {
  const workouts = S?.workouts || [];
  const inWin = muscleBalanceWindow(workouts, win, nowMs, todayIso, weekStartOf(S));
  const rated = inWin.some(w => (w.entries || []).some(e => (e.sets || []).some(s => s.done && isHardSet(s))));
  const on = hard && rated;
  const load = loadOfWorkouts(inWin, on ? isHardSet : null);
  const { worked, missed } = rankOf(load);
  const top = worked.slice(0, 4);
  const max = worked.length ? load[worked[0]] : 0;
  return {
    inWinCount: inWin.length,
    rated,
    on,
    load,
    levels: levelsOf(load),
    worked,
    missed,
    top: top.map(m => ({ slug: m, pct: max > 0 ? Math.round(load[m] / max * 100) : 0 })),
    sets: Object.fromEntries(MUSCLES.map(m => [m, Math.round((load[m] || 0) * 10) / 10]))
  };
}

/**
 * Fatigue view state and absolute shade levels.
 * Source: openGym frontend/src/views/Stats.jsx lines 114-118, 453.
 */
export function fatigueView(S, nowMs) {
  const workouts = S?.workouts || [];
  const bodyweightKg = bodyweightKgOf(S);
  const fatigue = fatigueOf(workouts, nowMs, { bodyweightKg, unit: S?.unit });
  return {
    fatigue,
    levels: levelsOf(fatigue, FATIGUE_LEVELS),
    states: Object.fromEntries(MUSCLES.map(m => [m, fatigueStateOf(fatigue[m])]))
  };
}

/**
 * Strength view state, absolute shade levels, detrained muscles and exercise history.
 * Source: openGym frontend/src/views/Stats.jsx lines 115, 134-138.
 */
export function strengthView(S, nowMs, sel) {
  const workouts = S?.workouts || [];
  const bodyweightKg = bodyweightKgOf(S);
  const strength = strengthOf(workouts, nowMs, { bodyweightKg, unit: S?.unit });
  const volWin = workouts.filter(w => (w.start || new Date(w.d).getTime()) > nowMs - 90 * 86400000);
  const vol90 = loadOfWorkouts(volWin, null);
  const lastTrained = latestMuscleTraining(workouts);
  const detrained = rankOf(strength).worked.filter(slug => strength[slug] < 1);
  return {
    strength,
    levels: levelsOf(strength, STRENGTH_LEVELS),
    strengthFloor: STRENGTH_FLOOR,
    detrained: detrained.map(slug => ({
      slug,
      pct: Math.round(strength[slug] * 100),
      sets90: Math.round((vol90[slug] || 0) * 10) / 10,
      weeks: lastTrained[slug] == null ? null : weeksSinceTraining(nowMs, lastTrained[slug])
    })),
    exercises: sel
      ? strengthExerciseRowsForMuscle(S, nowMs, sel).map(r => ({
          ...r,
          decayPct: Math.round(r.decay * 100)
        }))
      : []
  };
}

/**
 * Map from exercise ID to its trained muscles snapshot.
 * Source: openGym frontend/src/components/MuscleExplorer.jsx lines 34-37.
 */
export function muscleIndex(S, ids) {
  registerCustom(S?.customEx || []);
  const all = allExercises(S);
  const target = Array.isArray(ids) ? all.filter(e => ids.includes(e.id)) : all;
  const index = {};
  for (const e of target) {
    index[e.id] = musclesOf(e);
  }
  return index;
}
