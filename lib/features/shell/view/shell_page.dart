// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

/// The app's empty Material 3 shell (FND-05). No feature screens, tabs or
/// demo content live here: Phase 3 builds screens 1:1 from openGym's views
/// and plugs them into this frame (via `lib/core/router/app_router.dart`).
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('shell-scaffold'),
      appBar: AppBar(title: const Text('openGym')),
      body: const SizedBox.shrink(),
    );
  }
}
