// SPDX-License-Identifier: AGPL-3.0-or-later

import '../core/api/open_gym_api_client.dart';
import '../core/data/gym_state_repository.dart';
import '../core/js/js_engine_service.dart';

/// The app's composition root's dependency bag: everything
/// `lib/app/app.dart` provides through `MultiRepositoryProvider`.
///
/// Provides repository data access, API client generation, and the
/// openGym JavaScript calculation engine.
final class AppDependencies {
  const AppDependencies({
    required this.gymStateRepository,
    required this.apiClientFactory,
    required this.jsEngine,
  });

  final GymStateRepository gymStateRepository;
  final ApiClientFactory apiClientFactory;
  final JsEngineService jsEngine;
}
