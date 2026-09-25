// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/bloc/shell_bloc.dart';
import '../features/shell/bloc/shell_event.dart';
import '../features/shell/bloc/shell_state.dart';
import '../features/shell/data/theme_settings.dart';
import 'dependencies.dart';

/// The app's composition root: DI ([AppDependencies] via
/// [MultiRepositoryProvider]), the [ShellBloc] (via [BlocProvider]), and the
/// themed [MaterialApp.router] that wraps [createAppRouter]'s [GoRouter].
///
/// A [StatefulWidget] so the [GoRouter] is created exactly once (in
/// [State.initState]) and survives every [ShellBloc] rebuild -- creating a
/// new [GoRouter] per build would reset navigation state.
class OpenExerciseApp extends StatefulWidget {
  const OpenExerciseApp({super.key, required this.dependencies, this.router});

  final AppDependencies dependencies;

  /// Overridable for a throwaway verification script; the real app always
  /// uses [createAppRouter].
  final GoRouter? router;

  @override
  State<OpenExerciseApp> createState() => _OpenExerciseAppState();
}

class _OpenExerciseAppState extends State<OpenExerciseApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider.value(value: widget.dependencies.gymStateRepository),
        RepositoryProvider.value(value: widget.dependencies.apiClientFactory),
      ],
      child: BlocProvider<ShellBloc>(
        create: (context) => ShellBloc(
          repository: widget.dependencies.gymStateRepository,
        )..add(const ShellStarted()),
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
