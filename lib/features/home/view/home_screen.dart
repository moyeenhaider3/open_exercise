// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';
import '../../history/view/sheets/calendar_sheet.dart';
import '../../plan/view/sheets/starter_plan_sheet.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import 'widgets/bodyweight_card.dart';
import 'widgets/week_card.dart';

String _todaySubtitle() {
  final DateTime now = DateTime.now();
  final String day = now.day.toString();
  final String month = kMonthsLong[now.month - 1];
  final String weekday = kDayNames[now.weekday % 7];
  return '$weekday, $day $month';
}

/// Home tab root view.
/// Ports `../openGym/frontend/src/views/Home.jsx`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final bool showCheckIn = gymState.checkIn != false;
    final bool showWelcome = (gymState.routines == null || gymState.routines!.isEmpty) &&
        gymState.active == null;
    final int totalWorkouts = gymState.workouts?.length ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ScreenHeader(
            title: 'openGym',
            subtitle: _todaySubtitle(),
            trailing: AppIconButton(
              'gear',
              tooltip: t('Settings'),
              onPressed: () => context.go(AppRoutes.settings),
            ),
          ),
          BlocBuilder<HomeBloc, HomeState>(
            builder: (BuildContext context, HomeState state) {
              if (state is! HomeReady) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Week Card (week strip, 7 days, Today row, different workout button)
                  WeekCard(
                    ready: state,
                    gymState: gymState,
                  ),

                  // Gym check-in card (quick tap on arrival at gym)
                  if (showCheckIn)
                    AppCard(
                      onTap: () => context.go(AppRoutes.checkin),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 36.0,
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: palette.blue,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                alignment: Alignment.center,
                                child: const AppIcon('qr', size: 20.0, color: Colors.white),
                              ),
                              const SizedBox(width: 12.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    t('At the gym'),
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: palette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    t('Check in'),
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppIcon('chevronRight', size: 18.0, color: palette.muted),
                        ],
                      ),
                    ),

                  // Welcome card (only when no routines configured and no active session)
                  if (showWelcome)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 29.0,
                                height: 29.0,
                                decoration: BoxDecoration(
                                  color: palette.acc,
                                  borderRadius: BorderRadius.circular(7.0),
                                ),
                                alignment: Alignment.center,
                                child: const AppIcon('sparkles', size: 18.0, color: Colors.white),
                              ),
                              const SizedBox(width: 10.0),
                              Text(
                                t('Welcome!'),
                                style: const TextStyle(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            t('Set up your weekly routine to get going — or load a ready-made starter plan.'),
                            style: TextStyle(
                              fontSize: 13.0,
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          AppButton(
                            variant: AppButtonVariant.primary,
                            icon: 'sparkles',
                            label: Text(t('Load starter plan')),
                            onPressed: () => showStarterPlanSheet(context),
                          ),
                          const SizedBox(height: 8.0),
                          AppButton(
                            label: Text(t('Build my own plan')),
                            onPressed: () => context.go(AppRoutes.plan),
                          ),
                        ],
                      ),
                    ),

                  // Body weight card
                  BodyweightCard(
                    ready: state,
                    gymState: gymState,
                  ),

                  // Streak card (opens the calendar sheet)
                  AppCard(
                    onTap: () => showCalendarSheet(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                AppIcon('flame', size: 22.0, color: palette.orange),
                                const SizedBox(width: 7.0),
                                Text(
                                  t('{0} week streak', <Object?>[state.streak]),
                                  style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.021,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${state.view.wThisWeek}${state.view.plannedPerWeek > 0 ? ' / ${state.view.plannedPerWeek}' : ''} ${t('this week')} · ${t(totalWorkouts == 1 ? '{0} workout total' : '{0} workouts total', <Object?>[totalWorkouts])}',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                        AppIcon('calendar', size: 20.0, color: palette.muted),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
