// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../core/i18n/t.dart';
import '../../../core/ui_kit/rows.dart';

/// Exercise library browsing and search screen.
/// Plan 03-13 builds this screen with LibraryBloc, filter chips, and exercise items.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScreenHeader(
          title: t('Exercises'),
        ),
      ],
    );
  }
}
