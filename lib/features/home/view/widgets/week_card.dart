// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../plan/view/sheets/day_override_sheet.dart';
import '../../../workout/view/start_flow.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';

/// Card containing week strip navigation, 7 day cells, Today row and workout picker.
/// Ports `../openGym/frontend/src/views/Home.jsx` lines 68-124.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.ready,
    required this.gymState,
  });

  final HomeReady ready;
  final GymState gymState;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<Routine> todayRoutines = ready.todayRoutines;
    final Routine? routine = todayRoutines.isNotEmpty ? todayRoutines.first : null;
    final String todayName = todayRoutines.map((Routine r) => r.name).join(' + ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Week navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AppIconButton(
                'chevronLeft',
                tooltip: t('Previous week'),
                onPressed: () => context
                    .read<HomeBloc>()
                    .add(const HomeWeekOffsetChanged(-1)),
              ),
              Text(
                ready.weekLabel,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: palette.muted,
                ),
              ),
              AppIconButton(
                'chevronRight',
                tooltip: t('Next week'),
                onPressed: () => context
                    .read<HomeBloc>()
                    .add(const HomeWeekOffsetChanged(1)),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // 7 day strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ready.stripDays.map((HomeStripDay day) {
              final bool isToday = day.iso == ready.todayIso;
              final Color dotColor = day.done
                  ? palette.acc
                  : (day.overridden && day.planned
                      ? palette.orange
                      : (day.planned ? palette.muted : Colors.transparent));

              return Expanded(
                child: InkWell(
                  onTap: () => showDayOverrideSheet(context, day.iso),
                  borderRadius: BorderRadius.circular(10.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          kDayShort[day.weekday].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: palette.muted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          width: 31.0,
                          height: 31.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? palette.acc : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            day.dayOfMonth.toString(),
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                              color: isToday
                                  ? palette.onAcc
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          width: 5.0,
                          height: 5.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12.0),

          // Today row
          _TodayRow(
            ready: ready,
            gymState: gymState,
            routine: routine,
            todayName: todayName,
          ),

          // Choose a different workout button (only when no active session)
          if (gymState.active == null) ...<Widget>[
            const SizedBox(height: 4.0),
            Center(
              child: AppButton(
                variant: AppButtonVariant.ghost,
                small: true,
                icon: 'reset',
                label: Text(
                  t('Choose a different workout'),
                  style: TextStyle(color: palette.muted),
                ),
                onPressed: () => context.go(AppRoutes.workout),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.ready,
    required this.gymState,
    required this.routine,
    required this.todayName,
  });

  final HomeReady ready;
  final GymState gymState;
  final Routine? routine;
  final String todayName;

  void _onTap(BuildContext context) {
    if (gymState.active != null) {
      context.go(AppRoutes.workout);
    } else if (ready.todayRoutines.isNotEmpty) {
      startFlow(context, ready.todayIds);
    } else {
      showDayOverrideSheet(context, ready.todayIso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool isActive = gymState.active != null;
    final bool isDone = ready.doneToday != null;

    final Color iconBg = isActive
        ? palette.orange
        : (isDone
            ? palette.surface3
            : (routine != null ? palette.acc : palette.surface3));

    final String iconName = isActive
        ? 'timer'
        : (isDone
            ? 'checkCircle'
            : (routine != null ? glyphOf(routine!.emoji) : 'moon'));

    final Color iconColor = (isDone && !isActive) ? palette.green : Colors.white;

    String title;
    if (isActive) {
      title = t('{0} — in progress', <Object?>[gymState.active!.name ?? '']);
    } else if (isDone) {
      final String? doneName = ready.doneToday!.name;
      title = (doneName != null && doneName.isNotEmpty)
          ? t('{0} — done', <Object?>[doneName])
          : t('Workout done');
    } else if (routine != null) {
      title = todayName;
    } else {
      title = t('Rest day');
    }

    if (ready.todayOverridden && routine != null && !isDone) {
      title += ' · ${t('rescheduled')}';
    }

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 29.0,
              height: 29.0,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(7.0),
              ),
              alignment: Alignment.center,
              child: AppIcon(iconName, size: 18.0, color: iconColor),
            ),
            const SizedBox(width: 9.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    t('Today'),
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.012,
                    ),
                  ),
                  if (ready.next != null &&
                      ready.next!.weekday != null &&
                      ready.next!.routine != null &&
                      !isDone) ...<Widget>[
                    const SizedBox(height: 2.0),
                    Text(
                      t(
                        'Next session: {0}, {1}',
                        <Object?>[
                          t(kDayNames[ready.next!.weekday!]),
                          ready.next!.routine!.name,
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 13.0,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            if (isActive)
              _Tag(
                text: t('Resume'),
                color: palette.orange,
                background: palette.orange.withValues(alpha: 0.16),
              )
            else if (isDone)
              _Tag(
                text: t('Done'),
                color: palette.green,
                background: palette.green.withValues(alpha: 0.16),
              )
            else if (routine != null)
              _Tag(
                text: t('Start'),
                color: palette.acc,
                background: palette.acc.withValues(alpha: 0.16),
              )
            else
              AppIcon('plus', size: 16.0, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
