// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * Transcribed from ../openGym/frontend/src/lib/mobile.js lines 88-126
 * (REMINDER_WINDOW_DAYS, REMINDER_ID_BASE, LEGACY_REMINDER_IDS, buildReminderNotifications).
 *
 * mobile.js itself cannot be bundled: it dynamic-imports @capacitor/* and reads import.meta.env.
 * Logic is copied, not re-derived.
 *
 * Imports are restricted to third_party/opengym/lib/.
 */

import { t } from '../../../third_party/opengym/lib/i18n-core.js';
import { isoOf } from '../../../third_party/opengym/lib/format.js';
import { effectiveRoutineIds } from '../../../third_party/opengym/lib/history.js';

// Keep enough dates queued to cover normal app use between foregrounds without creating an
// unbounded notification list. The next sync cancels and replaces this whole window.
export const REMINDER_WINDOW_DAYS = 60;
export const REMINDER_ID_BASE = 1000;

// In mobile.js this is an array of objects { id: 100 + d }. Exporting the IDs as plain numbers
// keeps the Dart bridge simple.
export const LEGACY_REMINDER_IDS = Array.from({ length: 7 }, (_, d) => 100 + d);

/**
 * Pure date expansion for the native reminder.
 * The bridge passes epoch ms as nowMs because JS Date cannot cross the JSON boundary directly.
 */
export function buildReminderNotifications(S, nowMs) {
  const now = nowMs == null ? new Date() : new Date(nowMs);
  const r = S?.reminder;
  if (!r?.on) return [];
  const routines = Array.isArray(S.routines) ? S.routines : [];
  const completed = new Set((S.workouts || []).map(w => w.d));
  const state = { ...S, routines, week: S.week || {}, dayPlan: S.dayPlan || {} };
  const [hour, minute] = (r.time || '08:00').split(':').map(Number);
  if (!Number.isInteger(hour) || !Number.isInteger(minute)) return [];
  const date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12);
  const notifications = [];
  for (let offset = 0; offset < REMINDER_WINDOW_DAYS; offset++) {
    const day = new Date(date);
    day.setDate(date.getDate() + offset);
    const iso = isoOf(day);
    if (completed.has(iso)) continue;
    // A weekday can hold several routines; name them all, or fall back to a count.
    const dayRoutines = effectiveRoutineIds(state, iso).map(id => routines.find(x => x.id === id)).filter(Boolean);
    if (!dayRoutines.length) continue;
    const label = dayRoutines.length <= 2 ? dayRoutines.map(r => r.name).join(' + ') : t('{0} routines', dayRoutines.length);
    const at = new Date(day);
    at.setHours(hour, minute, 0, 0);
    if (at <= now) continue;
    notifications.push({
      id: REMINDER_ID_BASE + offset,
      title: t('Workout day'),
      body: t('{0} is on the plan today — let’s go!', label),
      schedule: { at, allowWhileIdle: true },
    });
  }
  return notifications;
}

/**
 * Fixture-only projection that drops the TZ-dependent schedule.at Date object so parity fixtures
 * remain strictly identical under any timezone (UTC, Asia/Kolkata, America/Los_Angeles).
 */
export function reminderDays(S, nowMs) {
  return buildReminderNotifications(S, nowMs).map(n => ({
    id: n.id,
    title: n.title,
    body: n.body,
  }));
}
