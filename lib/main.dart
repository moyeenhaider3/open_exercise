// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/api/open_gym_api_client.dart';
import 'core/backup/auto_backup_sync.dart';
import 'core/backup/backup_bookmark_channel.dart';
import 'core/backup/backup_folder_service.dart';
import 'core/backup/backup_repository.dart';
import 'core/backup/backup_settings_dao.dart';
import 'core/catalogue/exercise_catalogue.dart';
import 'core/data/gym_state_repository.dart';
import 'core/db/app_database.dart';
import 'core/js/js_engine_service.dart';
import 'core/js/modules/exercises_js.dart';
import 'core/js/modules/reminder_js.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_sync.dart';
import 'core/sound/timer_sound.dart';
import 'core/state/gym_state_cubit.dart';
import 'core/wakelock/wakelock_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase database;
  try {
    database = await AppDatabase.open(
      factory: databaseFactory,
      path: await AppDatabase.defaultPath(),
    );
  } catch (e, st) {
    // The shell must always boot (T-1-12): a failed open (disk full, corrupt
    // file, failed migration) shows a recovery screen instead of a blank app.
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'open_exercise bootstrap'),
    );
    runApp(const _StartupErrorApp(message: 'Could not open the local database.'));
    return;
  }

  final JsEngineService jsEngine;
  try {
    jsEngine = await JsEngineService.load();
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'open_exercise bootstrap'),
    );
    await database.close();
    runApp(const _StartupErrorApp(message: 'Could not start the calculation engine.'));
    return;
  }

  final ExerciseCatalogue exerciseCatalogue;
  try {
    exerciseCatalogue = await ExerciseCatalogue.load(rootBundle);
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'open_exercise bootstrap'),
    );
    await database.close();
    runApp(const _StartupErrorApp(message: 'Could not load exercise catalogue.'));
    return;
  }

  final GymStateRepository gymStateRepository = GymStateRepository(database: database);
  final GymStateCubit gymStateCubit = await GymStateCubit.load(
    repository: gymStateRepository,
    exercisesJs: jsEngine.exercises,
  );

  NotificationService notificationService;
  try {
    notificationService = await NotificationService.init();
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'NotificationService.init'),
    );
    notificationService = NotificationService.disabled();
  }

  TimerSound timerSound;
  try {
    timerSound = await TimerSound.create();
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'TimerSound.create'),
    );
    timerSound = TimerSound.silent();
  }

  timerSound.bind(gymStateCubit);
  WakelockSync.start(gymStateCubit);

  final ReminderSync reminderSync = ReminderSync(
    gymState: gymStateCubit,
    reminderJs: jsEngine.reminder,
    notifications: notificationService,
  );
  reminderSync.start();

  final BackupSettingsDao backupSettingsDao = BackupSettingsDao(database);
  const BackupBookmarkChannel backupBookmarkChannel = BackupBookmarkChannel();
  final BackupFolderService backupFolderService = BackupFolderService(
    settingsDao: backupSettingsDao,
    bookmarkChannel: backupBookmarkChannel,
  );
  final BackupRepository backupRepository = BackupRepository(
    gymStateRepository: gymStateRepository,
    folderService: backupFolderService,
    settingsDao: backupSettingsDao,
    uid: gymStateCubit.uid,
  );

  final AutoBackupSync autoBackupSync = AutoBackupSync(
    backupRepository: backupRepository,
    gymState: gymStateCubit,
    settingsDao: backupSettingsDao,
  );
  autoBackupSync.init();

  runApp(
    OpenExerciseApp(
      dependencies: AppDependencies(
        gymStateRepository: gymStateRepository,
        apiClientFactory: const ApiClientFactory(),
        jsEngine: jsEngine,
        exerciseCatalogue: exerciseCatalogue,
        notificationService: notificationService,
        reminderSync: reminderSync,
        timerSound: timerSound,
        backupRepository: backupRepository,
        autoBackupSync: autoBackupSync,
      ),
      gymStateCubit: gymStateCubit,
    ),
  );
}

/// Minimal fallback shown when the local database or JS engine cannot be opened
/// at startup. "Try again" re-runs the whole bootstrap.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'openGym',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: main,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
