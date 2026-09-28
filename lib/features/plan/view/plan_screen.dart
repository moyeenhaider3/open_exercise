// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../core/i18n/t.dart';
import '../../../core/ui_kit/rows.dart';

/// Weekly workout plan and routines screen.
/// Plan 03-11 builds this screen with PlanBloc, weekly plan calendar, and routine cards.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScreenHeader(
          title: t('Plan'),
        ),
      ],
    );
  }
}
