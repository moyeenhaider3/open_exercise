// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import 'app_tab_bar.dart';

/// The app's primary shell scaffold embedding [AppTabBar] and active child route.
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
        child: child,
      ),
      bottomNavigationBar: AppTabBar(location: location),
    );
  }
}
