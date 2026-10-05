// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/phase5_models.dart';

/// Typed facade for openGym lib/mobile.js lines 88-126 via reminder-shim.js.
final class ReminderJs {
  const ReminderJs(this._engine);

  final JsEngineService _engine;

  /// Days window for scheduling reminders (openGym default = 60).
  int get windowDays => jsInt(
        _engine.read('reminder.REMINDER_WINDOW_DAYS'),
        'reminder.REMINDER_WINDOW_DAYS',
      );

  /// Base notification ID offset (openGym default = 1000).
  int get idBase => jsInt(
        _engine.read('reminder.REMINDER_ID_BASE'),
        'reminder.REMINDER_ID_BASE',
      );

  /// Legacy reminder notification IDs (100..106).
  List<int> get legacyIds => jsIntList(
        _engine.read('reminder.LEGACY_REMINDER_IDS'),
        'reminder.LEGACY_REMINDER_IDS',
      );

  /// Builds scheduled reminder notifications from current GymState and nowMs.
  List<ReminderNotification> buildReminderNotifications(GymState s, int nowMs) {
    final Object? result = _engine.call(
      'reminder.buildReminderNotifications',
      <Object?>[s.toJson(), nowMs],
    );
    final List<Object?> rawList = jsList(result, 'reminder.buildReminderNotifications');
    return rawList
        .map((e) => ReminderNotification.fromJson(
              jsMap(e, 'reminder.buildReminderNotifications[]'),
            ))
        .toList();
  }

  /// Parity-only projection dropping the timezone-dependent `schedule.at`.
  List<Map<String, Object?>> reminderDays(GymState s, int nowMs) {
    final Object? result = _engine.call(
      'reminder.reminderDays',
      <Object?>[s.toJson(), nowMs],
    );
    final List<Object?> rawList = jsList(result, 'reminder.reminderDays');
    return rawList.map((e) => jsMap(e, 'reminder.reminderDays[]')).toList();
  }
}

extension ReminderJsAccess on JsEngineService {
  ReminderJs get reminder => ReminderJs(this);
}
