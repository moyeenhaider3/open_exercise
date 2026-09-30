// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase31_models.dart';
import '../../../../core/js/modules/effort_js.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/line_chart.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/stats_bloc.dart';
import '../../bloc/stats_event.dart';
import '../../bloc/stats_state.dart';

/// Card showing effort trends and distribution histogram.
/// Ports `../openGym/frontend/src/views/Stats.jsx` lines 236-284 (EffortCard).
class EffortCard extends StatelessWidget {
  const EffortCard({
    super.key,
    required this.ready,
  });

  final StatsReady ready;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final EffortSummary? summary = ready.effortSummary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header: Title and subtitle
          Row(
            children: <Widget>[
              Text(
                t('Effort'),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.015,
                ),
              ),
              Text(
                t(' · how close to failure'),
                style: TextStyle(
                  fontSize: 13.0,
                  color: palette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Window segmented control (30d / 90d / 1Y / All)
          AppSegmented<int>(
            options: const <SegmentOption<int>>[
              SegmentOption<int>(value: 30, label: '30d'),
              SegmentOption<int>(value: 90, label: '90d'),
              SegmentOption<int>(value: 365, label: '1Y'),
              SegmentOption<int>(value: 0, label: 'All'),
            ],
            value: ready.effortWindow,
            onChanged: (int days) {
              context.read<StatsBloc>().add(StatsEffortWindowChanged(days));
            },
          ),
          const SizedBox(height: 14.0),

          if (summary == null || summary.rated == 0) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                t('No rated sets in this period.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: palette.muted,
                ),
              ),
            ),
          ] else ...<Widget>[
            // Big stats: average effort and hard percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    () {
                      final num? avg = summary.avg;
                      final double? scaledAvg = avg != null
                          ? engine.effort.toScale(ready.kind, avg)
                          : null;
                      final String avgStr = scaledAvg != null
                          ? '${fmtNum(scaledAvg)} ${ready.hd}'
                          : '—';
                      return Text(
                        avgStr,
                        style: const TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02,
                        ),
                      );
                    }(),
                    const SizedBox(height: 2.0),
                    Text(
                      t('average effort'),
                      style: TextStyle(
                        fontSize: 12.0,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    () {
                      final num? hardPct = summary.hardPct;
                      final String pctStr = hardPct != null
                          ? '${(hardPct * 100).round()}%'
                          : '—';
                      return Text(
                        pctStr,
                        style: TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02,
                          color: palette.yellow,
                        ),
                      );
                    }(),
                    const SizedBox(height: 2.0),
                    () {
                      final double? scaledHard = engine.effort.toScale(
                        ready.kind,
                        ready.hardRir,
                      );
                      return Text(
                        t('at {0} {1} or harder', <Object?>[
                          ready.hd,
                          scaledHard != null
                              ? fmtNum(scaledHard)
                              : fmtNum(ready.hardRir),
                        ]),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: palette.muted,
                        ),
                      );
                    }(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6.0),

            // Rated fraction caption
            Text(
              t('{0} of {1} finished sets rated', <Object?>[
                summary.rated,
                summary.done,
              ]),
              style: TextStyle(
                fontSize: 12.0,
                color: palette.muted,
              ),
            ),

            // Warning note if effort logging switched off
            if (ready.effortMode == 'none') ...<Widget>[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: palette.yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  t('Effort per set is switched off — turn it on in Settings to keep rating.'),
                  style: TextStyle(
                    fontSize: 12.0,
                    color: palette.yellow,
                  ),
                ),
              ),
            ],

            if (ready.effortWeeks != null && ready.effortWeeks!.length > 1) ...<Widget>[
              const SizedBox(height: 16.0),
              Text(
                t('Week by week'),
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 8.0),
              () {
                final List<LineChartPoint> pts = <LineChartPoint>[
                  for (final EffortWeek w in ready.effortWeeks!)
                    LineChartPoint(
                      t: w.t,
                      y: engine.effort.toScale(ready.kind, w.rir) ?? w.rir,
                      note: t('{0} sets', <Object?>[w.sets]),
                    ),
                ];
                return LineChart(
                  points: pts,
                  height: 140.0,
                  unit: ready.hd,
                  color: palette.yellow,
                  invert: ready.kind == 'rir',
                );
              }(),
            ],

            if (ready.effortHistogram != null && ready.effortHistogram!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16.0),
              Text(
                t('Where the sets land'),
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 8.0),
              () {
                int maxN = 1;
                for (final EffortBin b in ready.effortHistogram!) {
                  if (b.n > maxN) maxN = b.n;
                }

                return Column(
                  children: <Widget>[
                    for (final EffortBin bin in ready.effortHistogram!) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 58.0,
                              child: Text(
                                () {
                                  final String binStr;
                                  if (ready.kind == 'rpe') {
                                    binStr = bin.tail
                                        ? '≤ 6'
                                        : '${10 - bin.rir}';
                                  } else {
                                    binStr = bin.tail
                                        ? '${bin.rir}+'
                                        : '${bin.rir}';
                                  }
                                  return '${ready.hd} $binStr';
                                }(),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (BuildContext ctx, BoxConstraints constraints) {
                                  final double barWidth =
                                      (bin.n / maxN).clamp(0.0, 1.0) *
                                          constraints.maxWidth;
                                  final Color barColor = bin.rir <= ready.hardRir
                                      ? palette.yellow
                                      : palette.surface3;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 16.0,
                                      width: barWidth > 0 ? barWidth : 0.0,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            SizedBox(
                              width: 76.0,
                              child: Text(
                                bin.n > 0
                                    ? '${bin.n} · ${(bin.pct * 100).round()}%'
                                    : '—',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }(),
            ],

            const SizedBox(height: 14.0),
            Text(
              t('Consistency near failure produces results — logging effort keeps you honest.'),
              style: TextStyle(
                fontSize: 12.0,
                color: palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
