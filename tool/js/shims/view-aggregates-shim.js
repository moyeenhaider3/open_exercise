// SPDX-License-Identifier: AGPL-3.0-or-later
/**
 * Transcribed from openGym views/sheets so the numbers these screens print run in the JS
 * engine (JS-04). Each export cites its source lines; logic is copied, not re-derived.
 *
 * Imports are restricted to third_party/opengym/lib/ so no UI/i18n code is pulled in.
 */

import { EXIDX, registerCustom, betterWeight } from '../../../third_party/opengym/lib/exercises.js';
import { lastBW, modeOf, metricModeForEntry, metricRowsForEntry, bestWeightForEntry } from '../../../third_party/opengym/lib/history.js';
import { isWarmupRow } from '../../../third_party/opengym/lib/workout-model.js';
import { avgRir, toScale } from '../../../third_party/opengym/lib/effort.js';
import { e1rmSeries, best1RM } from '../../../third_party/opengym/lib/onerm.js';
import { workoutVolume } from '../../../third_party/opengym/lib/history.js';
import { weekKey, weekStartOf } from '../../../third_party/opengym/lib/format.js';

// ---------------------------------------------------------------------------
// heatmapDays — Heatmap.jsx lines 11-19
// ---------------------------------------------------------------------------
/**
 * Aggregate workouts by ISO date and derive quartile thresholds for heatmap levels.
 * Source: openGym frontend/src/components/Heatmap.jsx lines 11-19.
 *
 * @param {Object} S  GymState
 * @returns {{ days: Object<string, {n:number, vol:number, min:number, level:number}>, t1:number, t2:number, t3:number }}
 */
export function heatmapDays(S) {
  const agg = {};
  (S.workouts || []).forEach(w => {
    const a = agg[w.d] = agg[w.d] || { n: 0, vol: 0, min: 0 };
    a.n++; a.vol += w.vol || 0;
    a.min += Math.max(0, Math.round(((w.end || w.start) - w.start) / 60000));
  });
  const mins = Object.values(agg).map(a => a.min).filter(v => v > 0).sort((a, b) => a - b);
  const q = p => (mins.length ? mins[Math.min(mins.length - 1, Math.floor(p * mins.length))] : 0);
  const t1 = q(0.25), t2 = q(0.5), t3 = q(0.75);
  // Assign level (l0..l4) per day based on minutes vs quartiles
  const level = min => {
    if (min <= 0) return 0;
    if (min <= t1) return 1;
    if (min <= t2) return 2;
    if (min <= t3) return 3;
    return 4;
  };
  const days = {};
  for (const [iso, a] of Object.entries(agg)) {
    days[iso] = { n: a.n, vol: a.vol, min: a.min, level: level(a.min) };
  }
  return { days, t1, t2, t3 };
}

// ---------------------------------------------------------------------------
// statsTiles — Stats.jsx lines 297-302
// ---------------------------------------------------------------------------
/**
 * Headline stat tile values: total workouts, workouts this calendar month, 30-day bw delta.
 * Source: openGym frontend/src/views/Stats.jsx lines 297-302.
 * `Date.now()` and `todayISO()` are replaced with explicit arguments for TZ stability.
 *
 * @param {Object} S          GymState
 * @param {number} nowMs      Current timestamp (ms since epoch)
 * @param {string} todayIso   Today's ISO date string (YYYY-MM-DD)
 * @returns {{ workouts:number, monthW:number, bwDelta30:number|null }}
 */
export function statsTiles(S, nowMs, todayIso) {
  const workouts = (S.workouts || []);
  const monthW = workouts.filter(w => String(w.d || '').slice(0, 7) === todayIso.slice(0, 7)).length;
  const bw30 = (S.bodyweight || []).filter(b => (b.t || new Date(b.d).getTime()) > nowMs - 30 * 86400000);
  const bwDelta30 = bw30.length > 1 ? bw30[bw30.length - 1].w - bw30[0].w : null;
  return { workouts: workouts.length, monthW, bwDelta30 };
}

// ---------------------------------------------------------------------------
// bodyweightPoints — Stats.jsx lines 297-298
// ---------------------------------------------------------------------------
/**
 * Bodyweight chart points filtered to a rolling window.
 * Source: openGym frontend/src/views/Stats.jsx lines 297-298.
 *
 * @param {Object} S          GymState
 * @param {number} rangeDays  Window in days; 0 = all history
 * @param {number} nowMs      Current timestamp (ms since epoch)
 * @returns {Array<{t:number, y:number, d:string}>}
 */
export function bodyweightPoints(S, rangeDays, nowMs) {
  return (S.bodyweight || [])
    .filter(b => rangeDays === 0 || (b.t || new Date(b.d).getTime()) > nowMs - rangeDays * 86400000)
    .map(b => ({ t: b.t || new Date(b.d).getTime(), y: b.w, d: b.d }));
}

// ---------------------------------------------------------------------------
// exerciseProgress — Stats.jsx lines 305-435
// ---------------------------------------------------------------------------
/**
 * Full exercise progress data for the Stats chart card.
 * Source: openGym frontend/src/views/Stats.jsx lines 305-435.
 *
 * UI/i18n substitutions:
 *  - `exerciseNameFor` replaced by `names[id]` lookup supplied by Dart
 *  - `t('reps')` replaced by literal string 'reps' (Dart localizes)
 *  - `localeCompare` sort tie-break uses `names[a]` vs `names[b]`
 *  - `hd + ' ' + fmtNum(...)` note string omitted; rirScale returned for Dart formatting
 *  - `exUnit` not returned; Dart derives from unitKind
 *
 * @param {Object} S            GymState
 * @param {string|null} exId    Currently selected exercise id (null = use first of exHist)
 * @param {string} kind         Display scale: 'rir' | 'rpe'
 * @param {Object} names        Map of { [id]: displayName } for sort and filter
 * @returns {Object} Full progress shape
 */
export function exerciseProgress(S, exId, kind, names) {
  registerCustom(S.customEx || []);

  const workouts = S.workouts || [];

  const nameOf = id => names[id] || id;

  const entryOf = id => workouts.flatMap(w => w.entries || []).find(e => e.id === id);

  const currentOf = id => {
    for (let i = workouts.length - 1; i >= 0; i--) {
      const en = (workouts[i].entries || []).find(e => e.id === id);
      if (!en) continue;
      const mode = metricModeForEntry(en) || modeOf({ id });
      const rows = metricRowsForEntry(en, mode);
      const mx = mode === 'reps'
        ? bestWeightForEntry(en)
        : Math.max(0, ...rows.map(s => mode === 'cardio' ? (s.speed || 0) : mode === 'time' ? (s.sec || 0) : (s.w || 0)));
      if (mx > 0) {
        const unitKind = mode === 'cardio' ? 'kmh' : mode === 'time' ? 's' : 'unit';
        return { mx, unitKind };
      }
      if (mode === 'reps') {
        const reps = Math.max(0, ...rows.map(s => Number(s.r) || 0));
        if (reps > 0) return { mx: reps, unitKind: 'reps' };
      }
    }
    return { mx: 0, unitKind: 'unit' };
  };

  const exHist = [...new Set(workouts.flatMap(w => (w.entries || []).map(e => e.id)))]
    .filter(id => EXIDX[id] || nameOf(id) !== id);
  const exCurrent = Object.fromEntries(exHist.map(id => [id, currentOf(id)]));
  exHist.sort((a, b) => exCurrent[b].mx - exCurrent[a].mx || nameOf(a).localeCompare(nameOf(b)));

  const curEx = exId && exHist.includes(exId) ? exId : (exHist[0] || null);

  const curMode = curEx ? (() => {
    for (let i = workouts.length - 1; i >= 0; i--) {
      const en = (workouts[i].entries || []).find(e => e.id === curEx);
      if (en) {
        const mode = metricModeForEntry(en);
        if (mode) return mode;
      }
    }
    return modeOf({ id: curEx });
  })() : 'reps';

  const curCardio = curMode === 'cardio';
  const curTimed = curMode === 'time';

  const repsOnly = curEx && curMode === 'reps' && !workouts.some(w => {
    const en = (w.entries || []).find(e => e.id === curEx);
    return en && bestWeightForEntry(en) > 0;
  });

  const bestRepsOf = en => Math.max(0, ...metricRowsForEntry(en, 'reps').map(s => Number(s.r) || 0));
  const metric = s => curCardio ? (s.speed || 0) : curTimed ? (s.sec || 0) : (s.w || 0);

  let exPts = [], exBest = 0;
  if (curEx) {
    workouts.forEach(w => {
      const en = (w.entries || []).find(e => e.id === curEx);
      if (en) {
        const loggedMode = metricModeForEntry(en);
        if (loggedMode !== curMode) return;
        const doneSets = metricRowsForEntry(en, curMode);
        const mx = curMode === 'reps'
          ? (repsOnly ? bestRepsOf(en) : bestWeightForEntry(en))
          : Math.max(0, ...doneSets.map(metric));
        if (mx > 0) {
          exPts.push({ t: w.start, y: mx, d: w.d, sets: doneSets, target: en.target || null });
          const better = curMode === 'reps' && !repsOnly
            ? betterWeight(curEx, exBest || mx, mx)
            : Math.max(exBest, mx);
          exBest = exBest > 0 ? better : mx;
        }
      }
    });
  }

  const exList = exPts.slice(-5).reverse();

  const e1Pts = curEx && curMode === 'reps' ? e1rmSeries(S, curEx) : [];
  const e1Best = curEx && curMode === 'reps' ? best1RM(S, curEx) : null;
  const showE1 = e1Pts.length > 0;

  const exRir = exPts.map(p => avgRir(p.sets));
  const showEff = exRir.filter(v => v != null).length >= 3;
  const effPts = exPts.map((p, i) => (exRir[i] == null ? null : { t: p.t, y: toScale(kind, exRir[i]), d: p.d })).filter(Boolean);

  // topPts: include m/rirScale only when the set is rated (avoids fixture key mismatch
  // with unrated series like bodyweightPoints that share the ChartPoint shape).
  const topPts = exPts.map((p, i) => {
    const pt = { t: p.t, y: p.y, d: p.d };
    if (exRir[i] != null) {
      pt.m = 1 - Math.min(4, Math.max(0, exRir[i])) / 4;
      pt.rirScale = toScale(kind, exRir[i]);
    }
    return pt;
  });

  // unitKind for curEx
  const curUnitKind = curCardio ? 'kmh' : curTimed ? 's' : repsOnly ? 'reps' : 'unit';

  // exHist shaped as ExerciseProgressOption
  const exHistOptions = exHist.map(id => ({ id, mx: exCurrent[id].mx, unitKind: exCurrent[id].unitKind }));

  return {
    exHist: exHistOptions,
    curEx,
    curMode,
    repsOnly,
    unitKind: curUnitKind,
    exPts: topPts,
    exList: exList.map(p => ({ d: p.d, sets: p.sets, target: p.target })),
    exBest,
    e1Pts: e1Pts.map(p => ({ t: p.t, y: p.y, d: p.d })),
    e1Best,
    effPts,
    showE1,
    showEff,
  };
}

// ---------------------------------------------------------------------------
// calendarMonth — sheets.jsx Calendar lines 1745-1786
// ---------------------------------------------------------------------------
/**
 * Aggregate totals for a calendar month: workout count, total volume, total duration ms.
 * Source: openGym frontend/src/sheets.jsx Calendar lines ~1773-1775.
 *
 * @param {Object} S    GymState
 * @param {number} y    Full year (e.g. 2026)
 * @param {number} mo   Month index 0-based (0 = January)
 * @returns {{ count:number, vol:number, ms:number }}
 */
export function calendarMonth(S, y, mo) {
  const prefix = y + '-' + String(mo + 1).padStart(2, '0');
  const monthWs = (S.workouts || []).filter(w => String(w.d || '').startsWith(prefix));
  const vol = monthWs.reduce((a, w) => a + (w.vol || 0), 0);
  const ms = monthWs.reduce((a, w) => a + Math.max(0, (w.end || w.start) - w.start), 0);
  return { count: monthWs.length, vol, ms };
}

// ---------------------------------------------------------------------------
// workoutDetailGroups — sheets.jsx WorkoutDetail lines 1666-1740
// ---------------------------------------------------------------------------
/**
 * Group a workout's entries by routine (rid) for the WorkoutDetail sheet header stats.
 * Source: openGym frontend/src/sheets.jsx WorkoutDetail lines ~1688-1720.
 *
 * @param {Object} w  Workout object
 * @returns {{ grouped:boolean, groups:Array<{key:string, rid:string|null, items:number[], setN:number, vol:number}> }}
 */
export function workoutDetailGroups(w) {
  const groups = [];
  (w.entries || []).forEach((e, i) => {
    const key = e.rid || '__none';
    let g = groups.find(x => x.key === key);
    if (!g) { g = { key, rid: e.rid || null, items: [] }; groups.push(g); }
    g.items.push(i);
  });
  const grouped = !!(groups.length > 1 || (groups[0] && groups[0].rid && ((w.routineIds || []).length > 1)));
  const result = groups.map(g => {
    const entries = g.items.map(i => (w.entries || [])[i]);
    const setN = entries.reduce((n, e) => {
      return n + (e.sets || []).filter(s => s.done && !isWarmupRow(s)).length;
    }, 0);
    const vol = workoutVolume({ entries });
    return { key: g.key, rid: g.rid, items: g.items, setN, vol };
  });
  return { grouped, groups: result };
}

// ---------------------------------------------------------------------------
// bwGoal — Home.jsx goal line; sheets.jsx GoalSheet
// ---------------------------------------------------------------------------
/**
 * Compute goal proximity using the last bodyweight entry.
 * Source: openGym frontend/src/views/Home.jsx lines ~162-165; sheets.jsx:569.
 *
 * @param {Object} S  GymState
 * @returns {null | { gap:number, reached:boolean, gain:boolean }}
 */
export function bwGoal(S) {
  if (S.targetW == null) return null;
  const bw = lastBW(S);
  if (!bw) return null;
  const gap = Math.abs(S.targetW - bw.w);
  const reached = gap < 0.05;
  const gain = S.targetW > bw.w;
  return { gap, reached, gain };
}

// ---------------------------------------------------------------------------
// homeView — Home.jsx main aggregates
// ---------------------------------------------------------------------------
/**
 * All derived numbers shown on the Home screen.
 * Source: openGym frontend/src/views/Home.jsx lines 30-58.
 *
 * @param {Object} S          GymState
 * @param {string} todayIso   Today's ISO date string (YYYY-MM-DD)
 * @returns {{ delta:number|null, deltaAbs:number|null, wThisWeek:number, plannedPerWeek:number, bwPoints:Array<{t:number,y:number,d:string}>, goal:Object|null }}
 */
export function homeView(S, todayIso) {
  const bw = lastBW(S);
  const prevBW = (S.bodyweight || []).length > 1 ? S.bodyweight[S.bodyweight.length - 2] : null;
  const delta = bw && prevBW ? bw.w - prevBW.w : null;
  const deltaAbs = delta != null ? Math.abs(delta) : null;

  const ws = weekStartOf(S);
  const wThisWeek = (S.workouts || []).filter(w => weekKey(w.d, ws) === weekKey(todayIso, ws)).length;
  const plannedPerWeek = Object.values(S.week || {}).filter(ids => ids?.length).length;

  const bwPoints = (S.bodyweight || []).slice(-30).map(b => ({
    t: b.t || new Date(b.d).getTime(),
    y: b.w,
    d: b.d,
  }));

  const goal = bwGoal(S);

  return { delta, deltaAbs, wThisWeek, plannedPerWeek, bwPoints, goal };
}
