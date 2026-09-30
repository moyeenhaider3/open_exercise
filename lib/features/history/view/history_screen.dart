// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/workout.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/rows.dart';
import 'sheets/log_past_workout_sheet.dart';
import 'sheets/workout_detail_sheet.dart';
import 'widgets/workout_row_tile.dart';

/// History screen displaying past workouts newest-first.
/// Ported 1:1 from `../openGym/frontend/src/views/History.jsx`.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<Workout> workouts = context.select<GymStateCubit, List<Workout>>(
      (GymStateCubit c) => c.state.workouts ?? const <Workout>[],
    );
    final int count = workouts.length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 12.0, 16.0, 8.0),
                    child: Row(
                      children: <Widget>[
                        AppIconButton(
                          'chevronLeft',
                          tooltip: t('Stats'),
                          onPressed: () => context.go(AppRoutes.stats),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                t('History'),
                                style: const TextStyle(
                                  fontSize: 28.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                t('{0} workouts', <Object>[count]),
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
                    child: AppButton(
                      icon: 'plus',
                      label: Text(t('Log a past workout')),
                      onPressed: () => showLogPastWorkoutSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              SliverList.builder(
                itemCount: count,
                itemBuilder: (BuildContext ctx, int index) {
                  final Workout w = workouts[count - 1 - index];
                  return WorkoutRowTile(
                    workout: w,
                    onTap: () => showWorkoutDetailSheet(context, w),
                  );
                },
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: 'history',
                  text: t('No workouts yet.'),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24.0),
            ),
          ],
        ),
      ),
    );
  }
}
