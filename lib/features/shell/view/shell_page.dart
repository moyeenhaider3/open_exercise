// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../workout/view/widgets/rest_timer_bar.dart';
import '../../workout/view/widgets/workout_timer_host.dart';
import 'app_tab_bar.dart';

/// The app's primary shell scaffold embedding [AppTabBar], [RestTimerBar]
/// (floating above the tab bar) and the active child route.
///
/// Body is wrapped in [WorkoutTimerHost] to forward lifecycle events to
/// [WorkoutTimerBloc] and surface the rest-over toast.
///
/// Ports openGym's main layout container from `../openGym/frontend/src/App.jsx`.
class ShellPage extends StatelessWidget {
  const ShellPage({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('shell-scaffold'),
      body: SafeArea(
        bottom: false,
        child: WorkoutTimerHost(child: child),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: const RestTimerBar(),
          ),
          AppTabBar(location: location),
        ],
      ),
    );
  }
}
