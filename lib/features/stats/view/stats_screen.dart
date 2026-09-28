// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../core/i18n/t.dart';
import '../../../core/ui_kit/rows.dart';

/// Stats tab root view.
/// Phase 3.1 (D-01) replaces this placeholder with charts and analytics.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScreenHeader(
          title: t('Stats'),
        ),
      ],
    );
  }
}
