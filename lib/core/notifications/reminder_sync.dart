// SPDX-License-Identifier: AGPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals

/// Port of `../openGym/frontend/src/lib/mobile.js` syncReminder (132-148) and
/// initReminderSync (153-165). Day selection runs in openGym's JS (ReminderJs, JS-04);
/// this class only cancels and schedules.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../js/models/phase5_models.dart';
import '../js/modules/reminder_js.dart';
import '../models/gym_state.dart';
import '../models/state_parts.dart';
import '../state/gym_state_cubit.dart';
import 'notification_service.dart';

/// Port of `../openGym/frontend/src/lib/mobile.js` `syncReminder` and `initReminderSync`.
///
/// Day selection runs in openGym's JS ([ReminderJs.buildReminderNotifications]); this class
/// only cancels and schedules notifications.
final class ReminderSync {
  ReminderSync({
    required GymStateCubit gymState,
    required ReminderJs reminderJs,
    required NotificationService notifications,
  })  : _gymState = gymState,
        _reminderJs = reminderJs,
        _notifications = notifications;

  final GymStateCubit _gymState;
  final ReminderJs _reminderJs;
  final NotificationService _notifications;

  StreamSubscription<GymState>? _subscription;
  Timer? _debounce;
  AppLifecycleListener? _lifecycleListener;

  /// Holds the last projection that was synced, used to skip unnecessary resyncs.
  _ReminderProjection? _lastSyncedProjection;

  /// Port of `mobile.js` `syncReminder` (lines 132-148).
  ///
  /// Cancels the legacy and current reminder ids, then schedules from
  /// [ReminderJs.buildReminderNotifications]. If [interactive], will request
  /// notification permissions from the user. Returns `true` on success, `false` otherwise.
  Future<bool> sync(GymState s, {bool interactive = false}) async {
    try {
      // Cancel legacy + current window ids (errors ignored, like mobile.js .catch(() => {}))
      final List<int> cancelIds = <int>[
        ..._reminderJs.legacyIds,
        ...List<int>.generate(
          _reminderJs.windowDays,
          (int d) => _reminderJs.idBase + d,
        ),
      ];
      await _notifications.cancelIds(cancelIds);

      // If reminder is off, return true (nothing to schedule)
      if (s.reminder?.on != true) return true;

      // Check permission
      bool allowed = await _notifications.notificationsAllowed();
      if (!allowed && interactive) {
        allowed = await _notifications.requestNotifications();
      }
      if (!allowed) return false;

      // Schedule from JS
      final List<ReminderNotification> notifications = _reminderJs.buildReminderNotifications(
        s,
        DateTime.now().millisecondsSinceEpoch,
      );
      for (final ReminderNotification n in notifications) {
        await _notifications.scheduleReminder(n);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Starts the reminder sync lifecycle.
  ///
  /// (a) On start, re-stamps reminder.tz if it differs from the local timezone
  ///     (useStore.js:601-605), then syncs once.
  /// (b) Subscribes to gymState.stream with an 800 ms debounce (useStore.js saveTm),
  ///     resyncing only when the relevant projection changes.
  /// (c) Listens to AppLifecycleListener.onResume to resync when the app returns
  ///     to the foreground (initReminderSync in mobile.js).
  ///
  /// All background syncs are non-interactive. Errors are caught inside.
  void start() {
    // (a) Re-stamp tz if needed, then initial sync
    _initialSync();

    // (b) Debounced state stream subscription (800 ms like useStore.js saveTm)
    _subscription = _gymState.stream.listen((GymState s) {
      final _ReminderProjection projection = _ReminderProjection.of(s);
      if (projection == _lastSyncedProjection) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        _lastSyncedProjection = projection;
        sync(s);
      });
    });

    // (c) AppLifecycleListener: resync on resume (initReminderSync)
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        sync(_gymState.state);
      },
    );
  }

  void _initialSync() {
    final GymState s = _gymState.state;
    if (s.reminder?.on == true) {
      final String localTz = _notifications.localTimezone;
      if (s.reminder!.tz != localTz) {
        _gymState.mutate(
          (GymState current) => current.copyWith(
            reminder: Reminder(
              on: current.reminder?.on,
              time: current.reminder?.time,
              tz: localTz,
              extra: current.reminder?.extra ?? const <String, Object?>{},
            ),
          ),
        );
      }
    }
    // Non-interactive initial sync using the (possibly updated) state
    sync(_gymState.state);
  }

  /// Cancels the subscription, timer and lifecycle listener.
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _lifecycleListener?.dispose();
    _debounce = null;
    _subscription = null;
    _lifecycleListener = null;
  }
}

/// Projection of [GymState] fields that [ReminderJs.buildReminderNotifications] reads.
///
/// Only these fields trigger a resync on state changes, matching the guard described in
/// the plan (reminder, week, dayPlan, routine ids + names, set of workout dates d).
class _ReminderProjection {
  const _ReminderProjection({
    required this.reminderOn,
    required this.reminderTime,
    required this.reminderTz,
    required this.week,
    required this.dayPlan,
    required this.routineIdsAndNames,
    required this.workoutDates,
  });

  factory _ReminderProjection.of(GymState s) {
    return _ReminderProjection(
      reminderOn: s.reminder?.on,
      reminderTime: s.reminder?.time,
      reminderTz: s.reminder?.tz,
      week: s.week,
      dayPlan: s.dayPlan,
      routineIdsAndNames: s.routines
              ?.map((r) => '${r.id}:${r.name}')
              .toList() ??
          const <String>[],
      workoutDates:
          s.workouts?.map((w) => w.d ?? '').toSet() ?? const <String>{},
    );
  }

  final bool? reminderOn;
  final String? reminderTime;
  final String? reminderTz;
  final Map<String, Object>? week;
  final Map<String, String>? dayPlan;
  final List<String> routineIdsAndNames;
  final Set<String> workoutDates;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _ReminderProjection) return false;
    if (reminderOn != other.reminderOn) return false;
    if (reminderTime != other.reminderTime) return false;
    if (reminderTz != other.reminderTz) return false;
    if (!_mapsEqual(week, other.week)) return false;
    if (!_mapsEqual(dayPlan, other.dayPlan)) return false;
    if (!_listsEqual(routineIdsAndNames, other.routineIdsAndNames)) return false;
    if (!_setsEqual(workoutDates, other.workoutDates)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        reminderOn,
        reminderTime,
        reminderTz,
        week,
        dayPlan,
        Object.hashAll(routineIdsAndNames),
        Object.hashAll(workoutDates),
      );

  static bool _mapsEqual(Map<dynamic, dynamic>? a, Map<dynamic, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final MapEntry<dynamic, dynamic> entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _setsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
