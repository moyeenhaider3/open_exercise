// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/format/format.dart';
import '../../../../core/format/set_label.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase3_models.dart';
import '../../../../core/js/modules/exercise_history_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/line_chart.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';

/// Opens the exercise history bottom sheet for [exId].
///
/// Ports `../openGym/frontend/src/sheets.jsx` ExerciseHistory lines 704-752.
Future<void> showExerciseHistorySheet(BuildContext context, String exId) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _ExerciseHistorySheet(exId: exId),
  );
}

class _ExerciseHistorySheet extends StatefulWidget {
  const _ExerciseHistorySheet({required this.exId});

  final String exId;

  @override
  State<_ExerciseHistorySheet> createState() => _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends State<_ExerciseHistorySheet> {
  String _curve = 'top';

  @override
  Widget build(BuildContext context) {
    final GymState gymState = context.watch<GymStateCubit>().state;
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final JsEngineService engine = context.read<JsEngineService>();
    final AppPalette palette = AppPalette.of(context);

    final ExerciseDef ex = catalogue.lookup(gymState, widget.exId);
    final String exName = catalogue.exerciseNameFor(ex);

    final ExerciseHistoryResult h =
        engine.exerciseHistory.exerciseHistory(gymState, widget.exId);

    if (h.total == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _capitalize(exName),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24.0),
          Center(
            child: Column(
              children: <Widget>[
                AppIcon('history', size: 36.0, color: palette.muted),
                const SizedBox(height: 8.0),
                Text(
                  t('No sessions logged yet'),
                  style: TextStyle(fontSize: 14.0, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      );
    }

    final String sessionUnit = h.metric == 'weight'
        ? (gymState.unit ?? 'kg')
        : h.metric == 'reps'
            ? t('reps')
            : h.metric == 'sec'
                ? 's'
                : t('min');

    final bool onE1 = _curve == 'e1rm' && h.e1rmPoints.isNotEmpty;
    final double e1Best = h.e1rmPoints.isEmpty
        ? 0.0
        : h.e1rmPoints
            .map((ExerciseHistoryPoint p) => p.y.toDouble())
            .reduce(math.max);

    final List<LineChartPoint> chartPoints = (onE1 ? h.e1rmPoints : h.points)
        .map((ExerciseHistoryPoint p) => LineChartPoint(
              t: p.t,
              y: p.y,
              d: p.d,
            ))
        .toList();

    final String activeUnit = onE1 ? (gymState.unit ?? 'kg') : sessionUnit;
    final num bestValue = onE1 ? e1Best : h.best;

    final String sessionsTitle = h.sessions.length < h.total
        ? t('Last {0} sessions', <Object?>[h.sessions.length])
        : t('Sessions');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _capitalize(exName),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2.0),
        Text(
          '${t('Exercise history')} · ${t(h.total == 1 ? '{0} session' : '{0} sessions', <Object?>[h.total])}',
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 12.0),
        if (h.e1rmPoints.isNotEmpty && h.metric == 'weight') ...<Widget>[
          AppSegmented<String>(
            value: _curve,
            options: <SegmentOption<String>>[
              SegmentOption<String>(value: 'top', label: t('Top set')),
              SegmentOption<String>(value: 'e1rm', label: t('Est. 1RM')),
            ],
            onChanged: (String v) => setState(() => _curve = v),
          ),
          const SizedBox(height: 8.0),
        ],
        LineChart(
          points: chartPoints,
          height: 140.0,
          unit: activeUnit,
          color: palette.blue,
        ),
        const SizedBox(height: 8.0),
        Row(
          children: <Widget>[
            AppIcon('trophy', size: 14.0, color: palette.yellow),
            const SizedBox(width: 5.0),
            Text(
              '${t('Best:')} ',
              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
            ),
            Text(
              '${fmtNum(bestValue)} $activeUnit',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: palette.acc,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Text(
          sessionsTitle,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: h.sessions.length,
          itemBuilder: (BuildContext ctx, int index) {
            final ExerciseHistorySession s = h.sessions[index];
            final String dateText = fmtDate(s.d, long: true);

            final String setsText = s.sets
                .map((SetEntry x) => setLabel(engine, widget.exId, x, s.target))
                .join('  ·  ');

            final List<String> tailParts = <String>[];
            if (s.volume != null && s.volume! > 0) {
              tailParts.add(
                '${t('Volume')} ${fmtVol(s.volume!, gymState.unit ?? 'kg')}',
              );
            }
            if (s.e1rm != null) {
              tailParts.add(
                '${t('Est. 1RM')} ${fmtNum(s.e1rm!)} ${gymState.unit ?? 'kg'}',
              );
            }
            final String tailText = tailParts.join(' · ');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              dateText,
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.pr) ...<Widget>[
                              const SizedBox(width: 6.0),
                              AppTag(
                                label: 'PR',
                                icon: 'trophy',
                                color: palette.yellow,
                              ),
                            ],
                          ],
                        ),
                        if (setsText.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 3.0),
                          Text(
                            setsText,
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Theme.of(ctx).colorScheme.onSurface,
                            ),
                          ),
                        ],
                        if (tailText.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2.0),
                          Text(
                            tailText,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: palette.dim,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (s.value != null && s.value! > 0)
                    Text(
                      '${fmtNum(s.value!)} $sessionUnit',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: palette.acc,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
