// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/t.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/rows.dart';

/// Scaffold screen for Settings (replaced by plan 03.1-07).
/// Ported from `../openGym/frontend/src/views/Settings.jsx`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 0),
              child: Row(
                children: <Widget>[
                  AppIconButton(
                    'chevronLeft',
                    tooltip: t('Home'),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
            ScreenHeader(
              title: t('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
