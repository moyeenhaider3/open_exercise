// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/catalogue/exercise_search.dart';
import '../../../../core/format/format.dart';
import '../../../../core/format/set_label.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase31_models.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/line_chart.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/stats_bloc.dart';
import '../../bloc/stats_event.dart';
import '../../bloc/stats_state.dart';

/// Resolves unit kind to display label.
String _unitLabel(String unitKind, String unit) {
  switch (unitKind) {
    case 'kmh':
      return 'km/h';
    case 's':
      return 's';
    case 'reps':
      return t('reps');
    case 'unit':
    default:
      return unit;
  }
}

/// Exercise progress card with searchable picker, metric toggle, trend chart, and recent sets.
/// Ports `../openGym/frontend/src/views/Stats.jsx` lines 305-435.
class ExerciseProgressCard extends StatelessWidget {
  const ExerciseProgressCard({
    super.key,
    required this.ready,
  });

  final StatsReady ready;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final GymState gymState = context.watch<GymStateCubit>().state;
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();

    final ExerciseProgress progress = ready.progress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('Exercise progress'),
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 12.0),

          if (progress.exHist.isEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                t('Finish your first workout to see progress curves here.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: palette.muted,
                ),
              ),
            ),
          ] else ...<Widget>[
            // Exercise picker SelectRow
            () {
              final List<SelectOption<String>> options = <SelectOption<String>>[
                for (final ExerciseProgressOption o in progress.exHist)
                  SelectOption<String>(
                    value: o.id,
                    label: () {
                      final ExerciseDef def = catalogue.lookup(gymState, o.id);
                      final String name = !def.missing ? def.n : o.id;
                      final String uLabel = _unitLabel(o.unitKind, ready.unit);
                      return o.mx > 0
                          ? '$name — ${fmtNum(o.mx)} $uLabel'
                          : name;
                    }(),
                  ),
              ];

              return SelectRow<String>(
                title: t('Exercise'),
                sheetTitle: t('Exercise progress'),
                value: progress.curEx ?? '',
                options: options,
                search: SearchConfig<String>(
                  placeholder: t('Search exercises'),
                  match: (SelectOption<String> option, String query) {
                    final ExerciseDef? def = catalogue.byId(option.value);
                    if (def != null) {
                      return matchesExerciseSearch(def, query);
                    }
                    return option.label.toLowerCase().contains(query.toLowerCase());
                  },
                ),
                onChanged: (String id) {
                  context.read<StatsBloc>().add(StatsExerciseSelected(id));
                },
              );
            }(),

            // Metric segmented button (if more than 1 option available)
            () {
              final List<SegmentOption<String>> metricOptions = <SegmentOption<String>>[
                SegmentOption<String>(value: 'top', label: t('Top set')),
                if (progress.showE1)
                  SegmentOption<String>(value: 'e1rm', label: t('Est. 1RM')),
                if (progress.showEff)
                  SegmentOption<String>(value: 'effort', label: t('Effort')),
              ];

              if (metricOptions.length <= 1) {
                return const SizedBox(height: 10.0);
              }

              return Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                child: AppSegmented<String>(
                  options: metricOptions,
                  value: ready.effectiveMetric,
                  onChanged: (String val) {
                    context.read<StatsBloc>().add(StatsExerciseMetricChanged(val));
                  },
                ),
              );
            }(),

            const SizedBox(height: 10.0),

            // Progress LineChart
            () {
              final String effMetric = ready.effectiveMetric;
              if (effMetric == 'effort') {
                final List<LineChartPoint> pts = <LineChartPoint>[
                  for (final ChartPoint p in progress.effPts)
                    LineChartPoint(t: p.t, y: p.y, d: p.d),
                ];
                return LineChart(
                  points: pts,
                  height: 160.0,
                  unit: ready.hd,
                  color: palette.yellow,
                  invert: ready.kind == 'rir',
                );
              } else if (effMetric == 'e1rm') {
                final List<LineChartPoint> pts = <LineChartPoint>[
                  for (final ChartPoint p in progress.e1Pts)
                    LineChartPoint(t: p.t, y: p.y, d: p.d),
                ];
                return LineChart(
                  points: pts,
                  height: 160.0,
                  unit: ready.unit,
                  color: palette.blue,
                );
              } else {
                final String uLabel = _unitLabel(progress.unitKind, ready.unit);
                final List<LineChartPoint> pts = <LineChartPoint>[
                  for (final ChartPoint p in progress.exPts)
                    LineChartPoint(
                      t: p.t,
                      y: p.y,
                      d: p.d,
                      m: p.m,
                      note: p.rirScale != null
                          ? '${ready.hd} ${fmtNum(p.rirScale!)}'
                          : null,
                    ),
                ];
                return LineChart(
                  points: pts,
                  height: 160.0,
                  unit: uLabel,
                  color: palette.blue,
                );
              }
            }(),

            const SizedBox(height: 10.0),

            // Caption: metric description + Best value
            () {
              final String effMetric = ready.effectiveMetric;
              final String metricCaption;
              if (effMetric == 'effort') {
                metricCaption = t('Average effort per workout');
              } else if (effMetric == 'e1rm') {
                metricCaption = t('Estimated 1RM per workout');
              } else {
                if (progress.curMode == 'cardio') {
                  metricCaption = t('Top speed per workout');
                } else if (progress.curMode == 'time') {
                  metricCaption = t('Longest hold per workout');
                } else if (progress.repsOnly) {
                  metricCaption = t('Most reps in a set per workout');
                } else {
                  metricCaption = t('Best set weight per workout');
                }
              }

              if (effMetric == 'effort') {
                return Text(
                  metricCaption,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: palette.muted,
                  ),
                );
              }

              final num bestVal = effMetric == 'e1rm'
                  ? (progress.e1Best?.est ?? 0)
                  : progress.exBest;
              final String bestUnit = effMetric == 'e1rm'
                  ? ready.unit
                  : _unitLabel(progress.unitKind, ready.unit);

              return Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: metricCaption,
                      style: TextStyle(
                        fontSize: 13.0,
                        color: palette.muted,
                      ),
                    ),
                    TextSpan(
                      text: ' · ${t('Best')}: ',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: palette.muted,
                      ),
                    ),
                    TextSpan(
                      text: '${fmtNum(bestVal)} $bestUnit',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: palette.acc,
                      ),
                    ),
                  ],
                ),
              );
            }(),

            // Extra line for e1rm
            if (ready.effectiveMetric == 'e1rm' && progress.e1Best != null) ...<Widget>[
              const SizedBox(height: 4.0),
              Text(
                t(
                  'Best estimate from {0} on {1} — an estimate, not a tested max.',
                  <Object?>[
                    '${fmtNum(progress.e1Best!.w)} ${ready.unit} × ${progress.e1Best!.r}',
                    fmtDate(progress.e1Best!.d, long: true),
                  ],
                ),
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.muted,
                ),
              ),
            ],

            // Extra line for top set with effort dot
            if (ready.effectiveMetric == 'top' && progress.showEff) ...<Widget>[
              const SizedBox(height: 4.0),
              Text(
                t(
                  'A fuller dot means less left in the tank — the same weight at a lower {0} is progress the line alone does not show.',
                  <Object?>[ready.hd],
                ),
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.muted,
                ),
              ),
            ],

            // Last 5 session rows
            if (progress.exList.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14.0),
              const Divider(height: 1.0),
              const SizedBox(height: 8.0),
              for (final ExerciseProgressRow row in progress.exList)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 90.0,
                        child: Text(
                          row.d != null ? fmtDate(row.d!, long: true) : '',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: palette.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.sets
                              .map(
                                (SetEntry s) => setLabel(
                                  engine,
                                  progress.curEx ?? '',
                                  s,
                                  row.target,
                                ),
                              )
                              .join('  '),
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
