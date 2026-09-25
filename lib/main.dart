// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/api/open_gym_api_client.dart';
import 'core/data/gym_state_repository.dart';
import 'core/db/app_database.dart';
import 'core/js/js_engine_service.dart';

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

  runApp(
    OpenExerciseApp(
      dependencies: AppDependencies(
        gymStateRepository: GymStateRepository(database: database),
        apiClientFactory: const ApiClientFactory(),
        jsEngine: jsEngine,
      ),
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
