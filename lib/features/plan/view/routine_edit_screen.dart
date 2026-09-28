// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../core/i18n/t.dart';
import '../../../core/ui_kit/rows.dart';

/// Routine editing screen.
/// Plan 03-14 builds this screen with routine name/emoji editing,
/// exercise reordering (ReorderableListView), and dismissal.
class RoutineEditScreen extends StatelessWidget {
  const RoutineEditScreen({
    super.key,
    required this.routineId,
  });

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScreenHeader(
          title: t('Routine'),
        ),
      ],
    );
  }
}
