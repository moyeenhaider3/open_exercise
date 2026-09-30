// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase31_models.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/view_aggregates_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../plan/view/sheets/day_override_sheet.dart';
import '../widgets/workout_row_tile.dart';
import 'workout_detail_sheet.dart';

/// Opens the Calendar bottom sheet for browsing history and scheduled sessions by month.
///
/// Ported 1:1 from `../openGym/frontend/src/sheets.jsx` Calendar lines 1745-1786.
Future<void> showCalendarSheet(BuildContext context, {String? start}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _CalendarSheet(start: start),
  );
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({this.start});

  final String? start;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _cur;

  @override
  void initState() {
    super.initState();
    final DateTime initial = widget.start != null
        ? (DateTime.tryParse(widget.start!) ?? DateTime.now())
        : DateTime.now();
    _cur = DateTime(initial.year, initial.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();

    final int y = _cur.year;
    final int mo = _cur.month - 1; // 0-based month index (0 = January)

    final Map<String, List<Workout>> byDay = <String, List<Workout>>{};
    for (final Workout w in gymState.workouts ?? const <Workout>[]) {
      if (w.d != null && w.d!.isNotEmpty) {
        (byDay[w.d!] ??= <Workout>[]).add(w);
      }
    }

    final int ws = weekStartOf(gymState);
    final int firstWeekday = DateTime(y, mo + 1, 1).weekday % 7;
    final int startOffset = weekDayOffset(firstWeekday, ws);
    final int daysIn = DateTime(y, mo + 2, 0).day;

    final CalendarMonthTotals totals = engine.viewAgg.calendarMonth(gymState, y, mo);
    final String unit = gymState.unit ?? 'kg';

    final String summaryText = totals.count > 0
        ? '${t(totals.count == 1 ? '{0} workout' : '{0} workouts', <Object>[totals.count])} · ${fmtDur(totals.ms)} · ${fmtVol(totals.vol, unit)}'
        : t('No workouts this month');

    final List<int> orderedDays = weekOrder(ws);
    final int totalCells = startOffset + daysIn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const AppIcon('chevronLeft', size: 18.0),
              onPressed: () {
                setState(() {
                  _cur = DateTime(y, mo, 1); // Previous month
                });
              },
              tooltip: 'Previous month',
            ),
            Text(
              '${t(kMonthsLong[mo])} $y',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
            IconButton(
              icon: const AppIcon('chevronRight', size: 18.0),
              onPressed: () {
                setState(() {
                  _cur = DateTime(y, mo + 2, 1); // Next month
                });
              },
              tooltip: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          summaryText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 10.0),
        Row(
          children: orderedDays.map((int dayIdx) {
            return Expanded(
              child: Center(
                child: Text(
                  t(kDayShort[dayIdx]).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: palette.dim,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 5.0,
            mainAxisSpacing: 5.0,
          ),
          itemCount: totalCells,
          itemBuilder: (BuildContext ctx, int index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }

            final int d = index - startOffset + 1;
            final String iso =
                '$y-${(mo + 1).toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
            final List<Workout>? wsDay = byDay[iso];
            final bool hasWorkouts = wsDay != null && wsDay.isNotEmpty;
            final bool planned =
                engine.history.effectiveRoutineIds(gymState, iso).isNotEmpty;
            final bool ovr = gymState.dayPlan?.containsKey(iso) ?? false;
            final bool isToday = iso == todayIso();

            final Color? dotColor = hasWorkouts
                ? palette.acc
                : (ovr && planned)
                    ? palette.orange
                    : planned
                        ? palette.dim
                        : null;

            return InkWell(
              borderRadius: BorderRadius.circular(10.0),
              onTap: () {
                if (!hasWorkouts) {
                  Navigator.of(context).pop();
                  showDayOverrideSheet(context, iso);
                  return;
                }
                if (wsDay.length == 1) {
                  Navigator.of(context).pop();
                  showWorkoutDetailSheet(context, wsDay.first);
                  return;
                }
                Navigator.of(context).pop();
                showAppSheet<void>(
                  context,
                  (BuildContext ctx2) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        fmtDate(iso, long: true),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ...wsDay.map((Workout w) => WorkoutRowTile(
                            workout: w,
                            onTap: () {
                              Navigator.of(ctx2).pop();
                              showWorkoutDetailSheet(context, w);
                            },
                          )),
                    ],
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: hasWorkouts
                      ? palette.acc.withValues(alpha: 0.15)
                      : palette.surface2,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isToday
                      ? Border.all(color: palette.acc, width: 1.8)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w400,
                        color: hasWorkouts ? palette.acc : null,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor ?? Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _legendItem(palette.acc, t('Trained'), palette.dim),
            const SizedBox(width: 14.0),
            _legendItem(palette.dim, t('Planned'), palette.dim),
            const SizedBox(width: 14.0),
            _legendItem(palette.orange, t('Rescheduled'), palette.dim),
          ],
        ),
        const SizedBox(height: 10.0),
        Text(
          t('Tap a trained day for details · tap any other day to plan a session'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.0, color: palette.dim),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, Color labelColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6.0,
          height: 6.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5.0),
        Text(
          label,
          style: TextStyle(fontSize: 12.0, color: labelColor),
        ),
      ],
    );
  }
}
