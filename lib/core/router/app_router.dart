// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:go_router/go_router.dart';

import '../../features/shell/view/shell_page.dart';

/// Named route paths. Phase 3 appends its own screens here as this app's
/// route table grows.
abstract final class AppRoutes {
  static const String shell = '/';
}

/// Builds the app's single [GoRouter]. Create exactly once (see
/// `lib/app/app.dart`) so rebuilds never reset navigation state.
GoRouter createAppRouter() {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.shell,
        name: 'shell',
        builder: (context, state) => const ShellPage(),
      ),
    ],
  );
}
