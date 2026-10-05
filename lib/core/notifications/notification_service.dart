// SPDX-License-Identifier: AGPL-3.0-or-later

/// Local notifications for the rest timer (TMR-02) and the workout-day reminder (TMR-03).
///
/// Replaces openGym's web push (push.js, /api/push/*) with on-device notifications (D-06);
/// nothing is sent to a server (D-02).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../i18n/t.dart';
import '../js/models/phase5_models.dart';

final class NotificationService {
  NotificationService._({
    required this.plugin,
    required this.localTimezone,
    required this.disabled,
  });

  static const int kRestNotificationId = 1;
  static const String kRestChannelId = 'rest-timer';
  static const String kReminderChannelId = 'workout-reminder';

  final FlutterLocalNotificationsPlugin? plugin;
  final String localTimezone;
  final bool disabled;

  /// Fallback no-op instance used when initialization fails or notifications are disabled.
  factory NotificationService.disabled() {
    return NotificationService._(
      plugin: null,
      localTimezone: 'UTC',
      disabled: true,
    );
  }

  /// Initializes timezone database and local notifications plugin!.
  ///
  /// Never prompts for permissions on init (Darwin initialization request flags are false).
  static Future<NotificationService> init() async {
    tz.initializeTimeZones();

    String resolvedTimezone = 'UTC';
    try {
      resolvedTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(resolvedTimezone));
    } catch (e) {
      debugPrint('NotificationService: failed to resolve local timezone: $e; falling back to UTC');
      resolvedTimezone = 'UTC';
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await plugin.initialize(settings: initSettings);

      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            AndroidNotificationChannel(
              kRestChannelId,
              t('Rest timer'),
              description: t('Alerts when rest countdown finishes'),
              importance: Importance.high,
            ),
          );
          await androidPlugin.createNotificationChannel(
            AndroidNotificationChannel(
              kReminderChannelId,
              t('Workout day reminder'),
              description: t('Reminders for planned workout days'),
              importance: Importance.defaultImportance,
            ),
          );
        }
      }

      return NotificationService._(
        plugin: plugin,
        localTimezone: resolvedTimezone,
        disabled: false,
      );
    } catch (e, st) {
      debugPrint('NotificationService.init failed: $e\n$st');
      return NotificationService.disabled();
    }
  }

  /// Non-interactive permission check.
  Future<bool> notificationsAllowed() async {
    if (disabled || plugin == null) return false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            plugin!.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final NotificationsEnabledOptions? options = await ios?.checkPermissions();
        return options?.isEnabled ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService.notificationsAllowed error: $e');
      return false;
    }
  }

  /// Interactive permission request prompt.
  Future<bool> requestNotifications() async {
    if (disabled || plugin == null) return false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            plugin!.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService.requestNotifications error: $e');
      return false;
    }
  }

  /// Check whether exact alarm scheduling is allowed.
  Future<bool> canScheduleExact() async {
    if (disabled || plugin == null) return false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.canScheduleExactNotifications() ?? false;
      }
      return true; // iOS / macOS do not require special exact alarm permissions
    } catch (e) {
      debugPrint('NotificationService.canScheduleExact error: $e');
      return false;
    }
  }

  /// Interactive request for SCHEDULE_EXACT_ALARM on Android (no-op on iOS).
  Future<void> requestExactAlarms() async {
    if (disabled || plugin == null) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('NotificationService.requestExactAlarms error: $e');
    }
  }

  /// Schedules rest timer completion alert at [endsAtMs] epoch milliseconds.
  Future<void> scheduleRestOver(int endsAtMs) async {
    if (disabled || plugin == null) return;
    try {
      final bool allowed = await notificationsAllowed();
      if (!allowed) return;

      final tz.TZDateTime scheduledDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local,
        endsAtMs,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        kRestChannelId,
        t('Rest timer'),
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        tag: 'rest-timer',
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final bool exactAllowed = await canScheduleExact();
      final AndroidScheduleMode mode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      try {
        await plugin!.zonedSchedule(
          id: kRestNotificationId,
          title: t('Rest over — next set!'),
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      } catch (scheduleErr) {
        debugPrint('NotificationService: exact schedule threw ($scheduleErr), retrying inexact...');
        await plugin!.zonedSchedule(
          id: kRestNotificationId,
          title: t('Rest over — next set!'),
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.scheduleRestOver error: $e');
    }
  }

  /// Cancels the scheduled rest completion alert.
  Future<void> cancelRestOver() async {
    if (disabled || plugin == null) return;
    try {
      await plugin!.cancel(id: kRestNotificationId);
    } catch (e) {
      debugPrint('NotificationService.cancelRestOver error: $e');
    }
  }

  /// Cancels a list of notification IDs.
  Future<void> cancelIds(Iterable<int> ids) async {
    if (disabled || plugin == null) return;
    try {
      for (final int id in ids) {
        await plugin!.cancel(id: id);
      }
    } catch (e) {
      debugPrint('NotificationService.cancelIds error: $e');
    }
  }

  /// Schedules a one-off daily reminder notification.
  Future<void> scheduleReminder(ReminderNotification n) async {
    if (disabled || plugin == null) return;
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(n.at, tz.local);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        kReminderChannelId,
        t('Workout day reminder'),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final bool exactAllowed = await canScheduleExact();
      final AndroidScheduleMode mode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      try {
        await plugin!.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      } catch (err) {
        debugPrint('NotificationService: reminder schedule threw ($err), retrying inexact...');
        await plugin!.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.scheduleReminder error: $e');
    }
  }
}
