// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/view/home_screen.dart';
import '../../features/library/view/library_screen.dart';
import '../../features/plan/view/plan_screen.dart';
import '../../features/plan/view/routine_edit_screen.dart';
import '../../features/shell/view/shell_page.dart';
import '../../features/stats/view/stats_screen.dart';
import '../../features/workout/view/workout_screen.dart';

/// Named route paths matching openGym routing structure.
abstract final class AppRoutes {
  static const String shell = '/';
  static const String home = '/home';
  static const String plan = '/plan';
  static const String routine = '/plan/r/:id';
  static const String workout = '/workout';
  static const String stats = '/stats';
  static const String library = '/library';

  /// Helper generating path for a specific routine ID.
  static String routinePath(String id) => '/plan/r/$id';
}

/// Builds the app's single [GoRouter].
///
/// NOTE: Plain [ShellRoute] (rather than stateful shell routes or [IndexedStack])
/// is deliberately used so that switching tabs remounts screens just like openGym's
/// React Router (`App.jsx`), cleanly resetting screen-local browse state.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ShellPage(
            location: state.uri.path,
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.plan,
            name: 'plan',
            builder: (BuildContext context, GoRouterState state) => const PlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.routine,
            name: 'routine',
            builder: (BuildContext context, GoRouterState state) {
              final String id = state.pathParameters['id'] ?? '';
              return RoutineEditScreen(key: ValueKey<String>(id), routineId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.workout,
            name: 'workout',
            builder: (BuildContext context, GoRouterState state) => const WorkoutScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            name: 'stats',
            builder: (BuildContext context, GoRouterState state) => const StatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            builder: (BuildContext context, GoRouterState state) => const LibraryScreen(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final String path = state.uri.path;
      if (path == AppRoutes.shell || path.isEmpty) {
        return AppRoutes.home;
      }
      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) => const HomeScreen(),
  );
}
