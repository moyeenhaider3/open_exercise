// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';

String _todaySubtitle() {
  final DateTime now = DateTime.now();
  final String day = now.day.toString();
  final String month = kMonthsLong[now.month - 1];
  final String weekday = kDayNames[now.weekday % 7];
  return '$weekday, $day $month';
}

/// Home tab root view.
/// Phase 3.1 (plan 03.1-11) builds the full overview and activity feed around this header and check-in card.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool showCheckIn = context.select<GymStateCubit, bool>(
      (GymStateCubit cubit) => cubit.state.checkIn != false,
    );

    return Column(
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
      ],
    );
  }
}
