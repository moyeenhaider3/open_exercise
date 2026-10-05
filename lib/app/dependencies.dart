// SPDX-License-Identifier: AGPL-3.0-or-later

import '../core/api/open_gym_api_client.dart';
import '../core/catalogue/exercise_catalogue.dart';
import '../core/data/gym_state_repository.dart';
import '../core/js/js_engine_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_sync.dart';
import '../core/sound/timer_sound.dart';

/// The app's composition root's dependency bag: everything
/// `lib/app/app.dart` provides through `MultiRepositoryProvider`.
///
/// Provides repository data access, API client generation, the
/// openGym JavaScript calculation engine, the exercise catalogue,
/// local notifications service, reminder sync, and timer audio/vibration feedback.
final class AppDependencies {
  const AppDependencies({
    required this.gymStateRepository,
    required this.apiClientFactory,
    required this.jsEngine,
    required this.exerciseCatalogue,
    required this.notificationService,
    required this.reminderSync,
    required this.timerSound,
  });

  final GymStateRepository gymStateRepository;
  final ApiClientFactory apiClientFactory;
  final JsEngineService jsEngine;
  final ExerciseCatalogue exerciseCatalogue;

  /// Local notifications for rest timers (TMR-02) and workout reminders (TMR-03).
  final NotificationService notificationService;

  /// Reminder schedule sync (TMR-03): port of mobile.js syncReminder/initReminderSync.
  final ReminderSync reminderSync;

  /// Audio and vibration feedback for timer ticks and completion.
  final TimerSound timerSound;
}
