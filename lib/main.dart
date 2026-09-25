// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/api/open_gym_api_client.dart';
import 'core/data/gym_state_repository.dart';
import 'core/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase database = await AppDatabase.open(
    factory: databaseFactory,
    path: await AppDatabase.defaultPath(),
  );

  runApp(
    OpenExerciseApp(
      dependencies: AppDependencies(
        gymStateRepository: GymStateRepository(database: database),
        apiClientFactory: const ApiClientFactory(),
      ),
    ),
  );
}
