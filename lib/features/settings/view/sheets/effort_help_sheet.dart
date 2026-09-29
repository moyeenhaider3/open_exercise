// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/modals.dart';

/// Opens the effort scale help modal sheet.
///
/// Ports openGym `views/Settings.jsx` effortHelpSheet (lines 512-533).
Future<void> showEffortHelpSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _EffortHelpSheet(),
  );
}

class _EffortHelpRow {
  const _EffortHelpRow({
    required this.rir,
    required this.rpe,
    required this.meaning,
    this.typical = false,
  });

  final String rir;
  final String rpe;
  final String meaning;
  final bool typical;
}

const List<_EffortHelpRow> _kEffortRows = <_EffortHelpRow>[
  _EffortHelpRow(rir: '0', rpe: '10', meaning: 'Nothing left — went to failure'),
  _EffortHelpRow(rir: '1', rpe: '9', meaning: 'One more rep in the tank'),
  _EffortHelpRow(rir: '2', rpe: '8', meaning: 'Two more reps', typical: true),
  _EffortHelpRow(rir: '3', rpe: '7', meaning: 'Three more reps'),
  _EffortHelpRow(rir: '4+', rpe: '≤6', meaning: 'Easy — warm-up territory'),
];

class _EffortHelpSheet extends StatelessWidget {
  const _EffortHelpSheet();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Effort scale'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          t('Rate how many reps you had left in the tank at the end of each set. openGym uses this to estimate recovery and suggest progression.'),
          style: TextStyle(fontSize: 14.0, color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 16.0),
        Container(
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 44.0,
                      child: Text(
                        'RIR',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44.0,
                      child: Text(
                        'RPE',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t('Meaning'),
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1.0),
              for (final _EffortHelpRow row in _kEffortRows)
                Container(
                  color: row.typical ? palette.acc.withValues(alpha: 0.12) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44.0,
                        child: Text(
                          row.rir,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: row.typical ? palette.acc : null,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44.0,
                        child: Text(
                          row.rpe,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: row.typical ? palette.acc : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t(row.meaning),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: row.typical ? palette.acc : null,
                            fontWeight: row.typical ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          t('Targeting 1–2 reps in reserve on working sets builds strength while avoiding burnout.'),
          style: TextStyle(fontSize: 13.0, color: palette.muted, height: 1.4),
        ),
      ],
    );
  }
}
