// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../format/format.dart';
import '../i18n/t.dart';
import '../theme/app_palette.dart';

/// Pre-aggregated daily training summary consumed by [Heatmap].
/// Aggregation is performed by bridged logic, never inside the UI widget.
final class HeatmapDayInfo {
  const HeatmapDayInfo({
    required this.n,
    required this.vol,
    required this.min,
    required this.level,
  });

  final int n;
  final num vol;
  final int min;
  final int level;
}

/// GitHub-style activity heatmap ported 1:1 from `../openGym/frontend/src/components/Heatmap.jsx`.
///
/// Draws 53 columns (52 weeks + current week) of 7 days shaded by training time.
/// Auto-scrolls horizontally to the newest column on initial mount.
class Heatmap extends StatefulWidget {
  const Heatmap({
    super.key,
    required this.days,
    required this.weekStart,
    required this.unit,
    this.onDay,
  });

  final Map<String, HeatmapDayInfo> days;
  final int weekStart;
  final String unit;
  final ValueChanged<String>? onDay;

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 10.0,
      height: 10.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day, 12);
    final String todayIsoString = todayIso();
    final int ws = widget.weekStart;

    final int dayOfWeek = today.weekday % 7;
    final DateTime end = DateTime(
      today.year,
      today.month,
      today.day - weekDayOffset(dayOfWeek, ws),
      12,
    );
    final DateTime start = DateTime(end.year, end.month, end.day - 52 * 7, 12);

    final List<String?> dayLabels = List<String?>.filled(7, null);
    dayLabels[weekDayOffset(1, ws)] = 'Mon';
    dayLabels[weekDayOffset(3, ws)] = 'Wed';
    dayLabels[weekDayOffset(5, ws)] = 'Fri';

    final List<Widget> monthWidgets = <Widget>[];
    final List<Widget> colWidgets = <Widget>[];
    int lastMonth = -1;

    for (int wk = 0; wk <= 52; wk++) {
      final DateTime colStart = DateTime(
        start.year,
        start.month,
        start.day + wk * 7,
        12,
      );
      final int mo = colStart.month - 1;
      final bool showM = mo != lastMonth && colStart.day <= 7 && wk < 51;
      monthWidgets.add(
        SizedBox(
          width: 14.0,
          child: Text(
            showM ? t(kMonths[mo]) : '',
            style: TextStyle(
              fontSize: 10.0,
              color: palette.muted,
              height: 1.0,
            ),
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ),
      );
      if (colStart.day <= 7) {
        lastMonth = mo;
      }

      final List<Widget> cells = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final DateTime day = DateTime(
          colStart.year,
          colStart.month,
          colStart.day + d,
          12,
        );
        final String key = isoOf(day);
        final HeatmapDayInfo? a = widget.days[key];
        final int lvl = a?.level ?? 0;

        Color cellColor;
        switch (lvl) {
          case 1:
            cellColor = Color.lerp(palette.surface2, palette.acc, 0.30)!;
          case 2:
            cellColor = Color.lerp(palette.surface2, palette.acc, 0.55)!;
          case 3:
            cellColor = Color.lerp(palette.surface2, palette.acc, 0.78)!;
          case 4:
            cellColor = palette.acc;
          case 0:
          default:
            cellColor = palette.surface2;
        }

        final bool isToday = key == todayIsoString;
        final bool isFuture = day.isAfter(today);
        if (isFuture) {
          cellColor = cellColor.withValues(alpha: 0.3);
        }

        final BoxBorder? border = isToday
            ? Border.all(color: palette.acc, width: 1.5)
            : null;

        final Widget cellBox = Container(
          width: 11.0,
          height: 11.0,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(3.0),
            border: border,
          ),
        );

        Widget cellWidget;
        if (a != null) {
          final String tooltipMsg =
              '$key · ${t(a.n == 1 ? '{0} workout' : '{0} workouts', <Object>[a.n])} · ${a.min} min · ${fmtVol(a.vol, widget.unit)}';
          cellWidget = Tooltip(
            message: tooltipMsg,
            child: GestureDetector(
              onTap: widget.onDay != null ? () => widget.onDay!(key) : null,
              behavior: HitTestBehavior.opaque,
              child: cellBox,
            ),
          );
        } else {
          cellWidget = cellBox;
        }

        cells.add(cellWidget);
      }

      colWidgets.add(
        Padding(
          padding: EdgeInsets.only(right: wk < 52 ? 3.0 : 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int c = 0; c < cells.length; c++)
                Padding(
                  padding: EdgeInsets.only(bottom: c < 6 ? 3.0 : 0.0),
                  child: cells[c],
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: monthWidgets,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 30.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (int i = 0; i < 7; i++)
                            Container(
                              height: 11.0,
                              margin: EdgeInsets.only(bottom: i < 6 ? 3.0 : 0.0),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                dayLabels[i] != null ? t(dayLabels[i]!) : '',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: palette.muted,
                                  height: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colWidgets,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 9.0, 14.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                t('Less time'),
                style: TextStyle(fontSize: 11.0, color: palette.muted),
              ),
              const SizedBox(width: 4.0),
              _legendBox(palette.surface2),
              const SizedBox(width: 4.0),
              _legendBox(Color.lerp(palette.surface2, palette.acc, 0.30)!),
              const SizedBox(width: 4.0),
              _legendBox(Color.lerp(palette.surface2, palette.acc, 0.55)!),
              const SizedBox(width: 4.0),
              _legendBox(Color.lerp(palette.surface2, palette.acc, 0.78)!),
              const SizedBox(width: 4.0),
              _legendBox(palette.acc),
              const SizedBox(width: 4.0),
              Text(
                t('More time'),
                style: TextStyle(fontSize: 11.0, color: palette.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
