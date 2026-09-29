// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/t.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/rows.dart';

/// Stats tab root view.
/// Phase 3.1 (plan 03.1-12) builds the full analytics and progress tiles around this header.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScreenHeader(
          title: t('Stats'),
          subtitle: t('Progress & history'),
          trailing: AppIconButton(
            'history',
            tooltip: t('History'),
            onPressed: () => context.go(AppRoutes.history),
          ),
        ),
      ],
    );
  }
}
