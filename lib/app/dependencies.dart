// SPDX-License-Identifier: AGPL-3.0-or-later

import '../core/api/open_gym_api_client.dart';
import '../core/data/gym_state_repository.dart';

/// The app's composition root's dependency bag: everything
/// `lib/app/app.dart` provides through `MultiRepositoryProvider`.
///
/// No `get_it` (or any other service locator) is used -- `RepositoryProvider`
/// is enough for Phase 1 (Research A5).
final class AppDependencies {
  const AppDependencies({
    required this.gymStateRepository,
    required this.apiClientFactory,
  });

  final GymStateRepository gymStateRepository;
  final ApiClientFactory apiClientFactory;
}
