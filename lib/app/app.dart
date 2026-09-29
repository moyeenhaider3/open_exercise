// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/api/open_gym_api_client.dart';
import '../core/catalogue/exercise_catalogue.dart';
import '../core/data/gym_state_repository.dart';
import '../core/js/js_engine_service.dart';
import '../core/router/app_router.dart';
import '../core/state/gym_state_cubit.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/bloc/shell_bloc.dart';
import '../features/shell/bloc/shell_event.dart';
import '../features/shell/bloc/shell_state.dart';
import '../features/shell/data/theme_settings.dart';
import 'dependencies.dart';
import 'providers/library_providers.dart';
import 'providers/plan_providers.dart';
import 'providers/workout_providers.dart';

/// The app's composition root: DI ([AppDependencies] via
/// [MultiRepositoryProvider]), the [GymStateCubit] (via [BlocProvider]), [ShellBloc],
/// feature Blocs, and the themed [MaterialApp.router] that wraps [createAppRouter]'s [GoRouter].
///
/// A [StatefulWidget] so the [GoRouter] is created exactly once (in
/// [State.initState]) and survives every [ShellBloc] rebuild -- creating a
/// new [GoRouter] per build would reset navigation state.
class OpenExerciseApp extends StatefulWidget {
  const OpenExerciseApp({
    super.key,
    required this.dependencies,
    required this.gymStateCubit,
    this.router,
  });

  final AppDependencies dependencies;
  final GymStateCubit gymStateCubit;

  /// Overridable for a throwaway verification script; the real app always
  /// uses [createAppRouter].
  final GoRouter? router;

  @override
  State<OpenExerciseApp> createState() => _OpenExerciseAppState();
}

class _OpenExerciseAppState extends State<OpenExerciseApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => unawaited(widget.gymStateCubit.flush()),
      onHide: () => unawaited(widget.gymStateCubit.flush()),
      onDetach: () => unawaited(widget.gymStateCubit.flush()),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GymStateRepository>.value(
          value: widget.dependencies.gymStateRepository,
        ),
        RepositoryProvider<ApiClientFactory>.value(
          value: widget.dependencies.apiClientFactory,
        ),
        RepositoryProvider<JsEngineService>.value(
          value: widget.dependencies.jsEngine,
        ),
        RepositoryProvider<ExerciseCatalogue>.value(
          value: widget.dependencies.exerciseCatalogue,
        ),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider>[
          BlocProvider<GymStateCubit>.value(value: widget.gymStateCubit),
          BlocProvider<ShellBloc>(
            create: (context) => ShellBloc(
              gymState: context.read<GymStateCubit>(),
            )..add(const ShellStarted()),
          ),
          ...libraryBlocProviders(widget.dependencies),
          ...workoutBlocProviders(widget.dependencies),
          ...planBlocProviders(widget.dependencies),
        ],
        child: BlocBuilder<ShellBloc, ShellState>(
          builder: (context, state) {
            switch (state) {
              case ShellInitial():
                const ThemeSettings settings = ThemeSettings.defaults();
                return MaterialApp.router(
                  title: 'openGym',
                  theme: buildAppTheme(Brightness.light, settings.accent),
                  darkTheme: buildAppTheme(Brightness.dark, settings.accent),
                  themeMode: settings.themeMode,
                  routerConfig: _router,
                );
              case ShellReady(:final settings):
                return MaterialApp.router(
                  title: 'openGym',
                  theme: buildAppTheme(Brightness.light, settings.accent),
                  darkTheme: buildAppTheme(Brightness.dark, settings.accent),
                  themeMode: settings.themeMode,
                  routerConfig: _router,
                );
            }
          },
        ),
      ),
    );
  }
}
