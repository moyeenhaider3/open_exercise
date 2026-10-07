// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/backup/backup_import_service.dart';
import '../../core/state/gym_state_cubit.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import '../dependencies.dart';

/// Per-feature BlocProvider list for Settings features.
/// Filled by plan 03.1-07.
List<BlocProvider> settingsBlocProviders(AppDependencies deps) => <BlocProvider>[
      BlocProvider<SettingsBloc>(
        create: (context) => SettingsBloc(
          gymState: context.read<GymStateCubit>(),
          engine: deps.jsEngine,
          reminderSync: deps.reminderSync,
          notifications: deps.notificationService,
          backupRepository: deps.backupRepository,
          backupImportService: const BackupImportService(),
        ),
      ),
    ];
