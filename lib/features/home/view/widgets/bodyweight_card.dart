// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/models/phase31_models.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/line_chart.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../bodyweight/view/bw_delta_color.dart';
import '../../../bodyweight/view/bw_sheet.dart';
import '../../../bodyweight/view/goal_sheet.dart';
import '../../bloc/home_state.dart';

/// Card displaying body weight headline metric, delta, goal proximity, and 30-entry chart.
/// Ports `../openGym/frontend/src/views/Home.jsx` lines 145-177.
class BodyweightCard extends StatelessWidget {
  const BodyweightCard({
    super.key,
    required this.ready,
    required this.gymState,
  });

  final HomeReady ready;
  final GymState gymState;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String unit = gymState.unit ?? 'kg';
    final num? targetW = gymState.targetW;
    final num? delta = ready.view.delta;
    final num? deltaAbs = ready.view.deltaAbs;
    final BwGoal? goal = ready.view.goal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header: Title and Goal / Log buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                t('Body weight'),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.015,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppButton(
                    variant: AppButtonVariant.plain,
                    small: true,
                    icon: 'target',
                    label: Text(
                      targetW != null ? fmtNum(targetW) : t('Goal'),
                      style: TextStyle(
                        color: targetW != null ? palette.yellow : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => showGoalSheet(context),
                  ),
                  const SizedBox(width: 8.0),
                  AppButton(
                    variant: AppButtonVariant.plain,
                    small: true,
                    icon: 'plus',
                    label: Text(t('Log')),
                    onPressed: () => showBwSheet(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          if (ready.bw != null && ready.bw!.w != null) ...<Widget>[
            // Metric headline row: current weight, delta arrow, and date
            () {
              final num currentW = ready.bw!.w!;
              final String dateIso = ready.bw!.d ?? '';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    fmtNum(currentW),
                    style: const TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 15.0,
                      color: palette.muted,
                    ),
                  ),
                  if (delta != null && delta != 0) ...<Widget>[
                    const SizedBox(width: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppIcon(
                          delta > 0 ? 'arrowUp' : 'arrowDown',
                          size: 12.0,
                          color: bwDeltaColor(context, delta, currentW, targetW),
                        ),
                        const SizedBox(width: 2.0),
                        Text(
                          fmtNum(deltaAbs ?? 0),
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: bwDeltaColor(context, delta, currentW, targetW),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Text(
                    fmtDate(dateIso, long: true),
                    style: TextStyle(
                      fontSize: 13.0,
                      color: palette.muted,
                    ),
                  ),
                ],
              );
            }(),

            // Goal proximity row
            if (targetW != null && goal != null) ...<Widget>[
              const SizedBox(height: 4.0),
              Row(
                children: <Widget>[
                  AppIcon('target', size: 13.0, color: palette.yellow),
                  const SizedBox(width: 5.0),
                  Expanded(
                    child: Text(
                      '${t('Goal')} ${fmtNum(targetW)} $unit · ${goal.reached ? t('reached!') : t(goal.gain ? '{0} to gain' : '{0} to lose', <Object?>['${fmtNum(goal.gap)} $unit'])}',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: palette.yellow,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Trend chart
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LineChart(
                points: ready.view.bwPoints
                    .map((ChartPoint p) =>
                        LineChartPoint(t: p.t, y: p.y, d: p.d, m: p.m))
                    .toList(),
                height: 130.0,
                unit: unit,
                goal: targetW,
              ),
            ),
          ] else ...<Widget>[
            Text(
              gymState.weighIn == false
                  ? t('No entries yet — log your weight to start the curve.')
                  : t("No entries yet — log your weight to start the curve. It's also asked before every workout."),
              style: TextStyle(
                fontSize: 13.0,
                color: palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
