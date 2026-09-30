// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/models/phase31_models.dart';
import '../../../core/models/workout.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/heatmap.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/line_chart.dart';
import '../../../core/ui_kit/rows.dart';
import '../../bodyweight/view/bw_delta_color.dart';
import '../../bodyweight/view/bw_sheet.dart';
import '../../bodyweight/view/goal_sheet.dart';
import '../../history/view/sheets/calendar_sheet.dart';
import '../../history/view/sheets/workout_detail_sheet.dart';
import '../../history/view/widgets/workout_row_tile.dart';
import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';
import 'widgets/effort_card.dart';
import 'widgets/exercise_progress_card.dart';
import 'widgets/muscle_balance_card.dart';

/// Stats tab root view.
/// Ports `../openGym/frontend/src/views/Stats.jsx` lines 287-513.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Widget _buildTile(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final AppPalette palette = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon(icon, size: 16.0, color: palette.muted),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocBuilder<StatsBloc, StatsState>(
      builder: (BuildContext context, StatsState state) {
        if (state is! StatsReady) {
          return const SizedBox.shrink();
        }

        final num? bwDelta30 = state.tiles.bwDelta30;
        final String bwDeltaStr = bwDelta30 == null
            ? '—'
            : '${bwDelta30 > 0 ? '+' : ''}${fmtNum(bwDelta30)} ${state.unit}';
        final Color bwDeltaCol = bwDeltaColor(
          context,
          bwDelta30,
          state.lastBw?.w ?? 0,
          state.targetWeight,
        );

        final List<Workout> recentWorkouts =
            state.workouts.reversed.take(6).toList();

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: t('Stats'),
                subtitle: t('Progress & history'),
                trailing: AppIconButton(
                  'history',
                  tooltip: t('History'),
                  onPressed: () => context.go(AppRoutes.history),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // 2x2 headline tiles
                    Row(
                      children: <Widget>[
                        _buildTile(
                          context,
                          icon: 'dumbbell',
                          label: t('Workouts'),
                          value: state.tiles.workouts.toString(),
                        ),
                        const SizedBox(width: 10.0),
                        _buildTile(
                          context,
                          icon: 'calendar',
                          label: t('This month'),
                          value: state.tiles.monthW.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: <Widget>[
                        _buildTile(
                          context,
                          icon: 'flame',
                          label: t('Week streak'),
                          value: state.streak.toString(),
                        ),
                        const SizedBox(width: 10.0),
                        _buildTile(
                          context,
                          icon: 'scale',
                          label: t('Weight 30d'),
                          value: bwDeltaStr,
                          valueColor: bwDeltaCol,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // Activity - last 12 months card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                t('Activity — last 12 months'),
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.015,
                                ),
                              ),
                              Text(
                                t(' · by time trained'),
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),
                          Heatmap(
                            days: state.heatmap,
                            weekStart: state.weekStart,
                            unit: state.unit,
                            onDay: (String iso) {
                              final List<Workout> dayWorkouts = state.workouts
                                  .where((Workout w) => w.d == iso)
                                  .toList();
                              if (dayWorkouts.length == 1) {
                                showWorkoutDetailSheet(
                                  context,
                                  dayWorkouts.first,
                                );
                              } else if (dayWorkouts.length > 1) {
                                showCalendarSheet(context, start: iso);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Muscle balance card (when workouts exist)
                    if (state.workouts.isNotEmpty) ...<Widget>[
                      const MuscleBalanceCard(),
                      const SizedBox(height: 14.0),
                    ],

                    // EffortCard (when hasEffort)
                    if (state.hasEffort) ...<Widget>[
                      EffortCard(ready: state),
                      const SizedBox(height: 14.0),
                    ],

                    // Body weight card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
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
                                      state.targetWeight != null
                                          ? fmtNum(state.targetWeight!)
                                          : t('Goal'),
                                      style: TextStyle(
                                        color: state.targetWeight != null
                                            ? palette.yellow
                                            : null,
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
                          const SizedBox(height: 12.0),
                          AppSegmented<int>(
                            options: const <SegmentOption<int>>[
                              SegmentOption<int>(value: 30, label: '1M'),
                              SegmentOption<int>(value: 90, label: '3M'),
                              SegmentOption<int>(value: 365, label: '1Y'),
                              SegmentOption<int>(value: 0, label: 'All'),
                            ],
                            value: state.range,
                            onChanged: (int days) {
                              context
                                  .read<StatsBloc>()
                                  .add(StatsRangeChanged(days));
                            },
                          ),
                          const SizedBox(height: 12.0),
                          () {
                            final List<LineChartPoint> pts = <LineChartPoint>[
                              for (final ChartPoint p in state.bwPoints)
                                LineChartPoint(t: p.t, y: p.y, d: p.d),
                            ];
                            return LineChart(
                              points: pts,
                              height: 160.0,
                              unit: state.unit,
                              goal: state.targetWeight,
                            );
                          }(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // ExerciseProgressCard
                    ExerciseProgressCard(ready: state),
                    const SizedBox(height: 14.0),

                    // Recent workouts section
                    if (state.workouts.isNotEmpty) ...<Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            t('Recent workouts'),
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.015,
                            ),
                          ),
                          AppButton(
                            variant: AppButtonVariant.plain,
                            small: true,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  t(
                                    'All {0}',
                                    <Object>[state.workouts.length],
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const AppIcon('chevronRight', size: 14.0),
                              ],
                            ),
                            onPressed: () => context.go(AppRoutes.history),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            for (final Workout w in recentWorkouts)
                              WorkoutRowTile(
                                workout: w,
                                onTap: () => showWorkoutDetailSheet(context, w),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
