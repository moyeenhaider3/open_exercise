// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../format/format.dart';
import '../i18n/t.dart';
import '../theme/app_palette.dart';

/// Point representation for [LineChart].
///
/// Ports `../openGym/frontend/src/components/LineChart.jsx` points:
/// `[{ t: ms, y: num, d?: iso, m?: 0..1, note?: str }]`.
class LineChartPoint {
  const LineChartPoint({
    num? t,
    num? x,
    required this.y,
    this.d,
    this.m,
    this.note,
  }) : t = t ?? x ?? 0;

  final num t;
  final num y;
  final String? d;
  final num? m;
  final String? note;

  num get x => t;
}

/// Native interactive SVG-style line chart ported from openGym `LineChart.jsx`.
///
/// Features:
/// - ViewBox W=340 scaled to layout width.
/// - Padded Y domain with "nice" step selection ({1, 2, 2.5, 5, 10} × 10^n).
/// - Monthly or date X gridlines.
/// - Gradient area fill and rounded stroke.
/// - Optional marked points (m) and dashed goal line.
/// - Touch / drag hover inspection showing date, formatted value, unit and note.
class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
    required this.points,
    required this.height,
    this.unit = '',
    this.color,
    this.goal,
    this.axes = true,
    this.invert = false,
  });

  final List<LineChartPoint> points;
  final double height;
  final String unit;
  final Color? color;
  final num? goal;
  final bool axes;
  final bool invert;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  _HoverInfo? _hover;

  @override
  void didUpdateWidget(LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points)) {
      _hover = null;
    }
  }

  void _onInteraction(Offset localPos, Size size) {
    if (widget.points.isEmpty) return;
    final List<LineChartPoint> pts = widget.points.length == 1
        ? <LineChartPoint>[widget.points[0], widget.points[0]]
        : widget.points;

    final double w = size.width > 0 ? size.width : 340.0;
    final double h = widget.height > 0 ? widget.height : 150.0;
    final double pl = widget.axes ? 34.0 : 8.0;
    final double pr = 12.0;
    final double pt = 10.0;
    final double pb = widget.axes ? 22.0 : 8.0;

    final num t0 = pts[0].t;
    final num t1 = pts[pts.length - 1].t != t0
        ? pts[pts.length - 1].t
        : t0 + 1;

    double ymin = pts.map((LineChartPoint p) => p.y.toDouble()).reduce(math.min);
    double ymax = pts.map((LineChartPoint p) => p.y.toDouble()).reduce(math.max);
    if (widget.goal != null && widget.goal!.isFinite) {
      ymin = math.min(ymin, widget.goal!.toDouble());
      ymax = math.max(ymax, widget.goal!.toDouble());
    }
    if (ymin == ymax) {
      ymin -= 1.0;
      ymax += 1.0;
    }
    final double pad = (ymax - ymin) * 0.12;
    ymin -= pad;
    ymax += pad;

    final double scaleX = w / 340.0;
    final double scaleY = h / widget.height;

    double calcX(num t) {
      if (t1 == t0) return ((pl + 340.0 - pr) / 2.0) * scaleX;
      return (pl + (t - t0) / (t1 - t0) * (340.0 - pl - pr)) * scaleX;
    }

    double calcY(num y) {
      final double f = (y - ymin) / (ymax - ymin);
      final double raw = pt + (widget.invert ? f : (1.0 - f)) * (widget.height - pt - pb);
      return raw * scaleY;
    }

    final List<LineChartPoint> hoverSource = widget.points.length == 1
        ? <LineChartPoint>[widget.points[0]]
        : widget.points;

    final List<String> hoverDates = hoverSource
        .map((LineChartPoint p) =>
            p.d ?? isoOf(DateTime.fromMillisecondsSinceEpoch(p.t.toInt())))
        .toList();
    final bool showYear = hoverDates
            .map((String iso) =>
                DateTime.tryParse('${iso}T12:00:00')?.year ?? 0)
            .toSet()
            .length >
        1;

    _HoverInfo? best;
    double bestDist = double.infinity;
    for (int i = 0; i < hoverSource.length; i++) {
      final LineChartPoint p = hoverSource[i];
      final double px = calcX(p.t);
      final double py = calcY(p.y);
      final double dist = (px - localPos.dx).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = _HoverInfo(
          x: px,
          y: py,
          iso: hoverDates[i],
          v: p.y,
          note: p.note,
          showYear: showYear,
        );
      }
    }

    setState(() {
      _hover = best;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            t('No data yet'),
            style: TextStyle(
              fontSize: 13.0,
              color: AppPalette.of(context).muted,
            ),
          ),
        ),
      );
    }

    final AppPalette palette = AppPalette.of(context);
    final Color chartColor = widget.color ?? palette.acc;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, widget.height);

          return GestureDetector(
            onPanDown: (DragDownDetails d) =>
                _onInteraction(d.localPosition, size),
            onPanUpdate: (DragUpdateDetails d) =>
                _onInteraction(d.localPosition, size),
            onPanEnd: (_) => setState(() => _hover = null),
            onPanCancel: () => setState(() => _hover = null),
            onTapDown: (TapDownDetails d) =>
                _onInteraction(d.localPosition, size),
            onTapUp: (_) => setState(() => _hover = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                CustomPaint(
                  size: size,
                  painter: _LineChartPainter(
                    points: widget.points,
                    height: widget.height,
                    color: chartColor,
                    palette: palette,
                    unit: widget.unit,
                    goal: widget.goal,
                    axes: widget.axes,
                    invert: widget.invert,
                    hover: _hover,
                  ),
                ),
                if (_hover != null) _buildTooltip(size, palette),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTooltip(Size size, AppPalette palette) {
    final _HoverInfo h = _hover!;
    final double cw = size.width;
    final double ch = size.height;
    const double m = 4.0;
    const double approxWidth = 140.0;
    const double approxHeight = 28.0;

    final double left =
        (h.x - approxWidth / 2.0).clamp(m, math.max(m, cw - approxWidth - m));
    final double top = h.y < approxHeight + 14.0
        ? math.min(ch - approxHeight - m, h.y + 14.0)
        : m;

    final String dateStr = fmtDate(h.iso, long: true, withYear: h.showYear);
    final String valStr = fmtNum(h.v);
    final String unitStr = widget.unit.isNotEmpty ? ' ${widget.unit}' : '';
    final String noteStr = h.note != null ? ' · ${h.note}' : '';

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: palette.surface3,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: palette.sep),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$dateStr · $valStr$unitStr$noteStr',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverInfo {
  const _HoverInfo({
    required this.x,
    required this.y,
    required this.iso,
    required this.v,
    this.note,
    required this.showYear,
  });

  final double x;
  final double y;
  final String iso;
  final num v;
  final String? note;
  final bool showYear;
}

/// Custom painter porting `LineChart.jsx` SVG rendering.
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.height,
    required this.color,
    required this.palette,
    required this.unit,
    this.goal,
    this.axes = true,
    this.invert = false,
    this.hover,
  });

  final List<LineChartPoint> points;
  final double height;
  final Color color;
  final AppPalette palette;
  final String unit;
  final num? goal;
  final bool axes;
  final bool invert;
  final _HoverInfo? hover;

  /// Pure arithmetic 10^floor(log10(raw)) via repeated multiplication (JS-04 safe).
  static double _calcPow10(double raw) {
    if (raw <= 0 || !raw.isFinite) return 1.0;
    double p = 1.0;
    if (raw >= 1.0) {
      while (p * 10.0 <= raw) {
        p *= 10.0;
      }
      return p;
    } else {
      while (p > raw) {
        p /= 10.0;
      }
      return p;
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashLength = 2.0,
    double spaceLength = 4.0,
  }) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double totalLength = math.sqrt(dx * dx + dy * dy);
    if (totalLength == 0) return;

    final double unitX = dx / totalLength;
    final double unitY = dy / totalLength;

    double current = 0.0;
    while (current < totalLength) {
      final double seg = math.min(dashLength, totalLength - current);
      canvas.drawLine(
        Offset(p1.dx + unitX * current, p1.dy + unitY * current),
        Offset(p1.dx + unitX * (current + seg), p1.dy + unitY * (current + seg)),
        paint,
      );
      current += dashLength + spaceLength;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double w = size.width;
    final double h = height;
    final double pl = axes ? 34.0 : 8.0;
    final double pr = 12.0;
    final double pt = 10.0;
    final double pb = axes ? 22.0 : 8.0;

    final bool single = points.length == 1;
    final List<LineChartPoint> pts =
        single ? <LineChartPoint>[points[0], points[0]] : points;

    final List<double> ys =
        pts.map((LineChartPoint p) => p.y.toDouble()).toList();
    double ymin = ys.reduce(math.min);
    double ymax = ys.reduce(math.max);

    if (goal != null && goal!.isFinite) {
      ymin = math.min(ymin, goal!.toDouble());
      ymax = math.max(ymax, goal!.toDouble());
    }
    if (ymin == ymax) {
      ymin -= 1.0;
      ymax += 1.0;
    }
    final double pad = (ymax - ymin) * 0.12;
    ymin -= pad;
    ymax += pad;

    final num t0 = pts[0].t;
    final num t1 = pts[pts.length - 1].t != t0
        ? pts[pts.length - 1].t
        : t0 + 1;

    final double scaleX = w / 340.0;
    final double scaleY = h / height;

    double calcX(num t) {
      if (t1 == t0) return ((pl + 340.0 - pr) / 2.0) * scaleX;
      return (pl + (t - t0) / (t1 - t0) * (340.0 - pl - pr)) * scaleX;
    }

    double calcY(num y) {
      final double f = (y - ymin) / (ymax - ymin);
      final double raw =
          pt + (invert ? f : (1.0 - f)) * (height - pt - pb);
      return raw * scaleY;
    }

    final Paint sepPaint = Paint()
      ..color = palette.sep.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Gridlines
    if (axes) {
      final double range = ymax - ymin;
      final double raw = range / 3.0;
      final double pow10 = _calcPow10(raw);
      double step = 10.0 * pow10;
      for (final double m in <double>[1.0, 2.0, 2.5, 5.0, 10.0]) {
        if (raw <= m * pow10) {
          step = m * pow10;
          break;
        }
      }

      final double startV = (ymin / step).ceil() * step;
      for (double v = startV; v <= ymax + 1e-9; v += step) {
        final double y = calcY(v);
        _drawDashedLine(
          canvas,
          Offset(pl * scaleX, y),
          Offset((340.0 - pr) * scaleX, y),
          sepPaint,
        );

        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: fmtNum(v),
            style: TextStyle(
              fontSize: 9.5,
              color: palette.muted,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((pl - 5.0) * scaleX - tp.width, y - tp.height / 2.0));
      }

      // X gridlines (monthly or 3 date ticks)
      final DateTime d0 = DateTime.fromMillisecondsSinceEpoch(t0.toInt());
      final DateTime d1 = DateTime.fromMillisecondsSinceEpoch(t1.toInt());
      final List<({int t, String txt, String? anchor})> ticks =
          <({int t, String txt, String? anchor})>[];

      DateTime mDate = DateTime(d0.year, d0.month + 1, 1);
      while (!mDate.isAfter(d1)) {
        ticks.add((
          t: mDate.millisecondsSinceEpoch,
          txt: t(kMonths[mDate.month - 1]),
          anchor: 'middle',
        ));
        mDate = DateTime(mDate.year, mDate.month + 1, 1);
      }

      if (ticks.isEmpty && !single) {
        for (int i = 0; i <= 2; i++) {
          final int tv = (t0 + (t1 - t0) * i / 2.0).toInt();
          final DateTime dd = DateTime.fromMillisecondsSinceEpoch(tv);
          ticks.add((
            t: tv,
            txt: '${dd.day} ${t(kMonths[dd.month - 1])}',
            anchor: i == 0 ? 'start' : (i == 2 ? 'end' : 'middle'),
          ));
        }
      }

      final int every = math.max(1, (ticks.length / 7.0).ceil());
      for (int i = 0; i < ticks.length; i++) {
        if (i % every != 0) continue;
        final ({String? anchor, int t, String txt}) tk = ticks[i];
        final double x = calcX(tk.t);
        _drawDashedLine(
          canvas,
          Offset(x, pt * scaleY),
          Offset(x, (height - pb) * scaleY),
          sepPaint,
        );

        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: tk.txt,
            style: TextStyle(
              fontSize: 9.5,
              color: palette.muted,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        double xOffset = x - tp.width / 2.0;
        if (tk.anchor == 'start') xOffset = x;
        if (tk.anchor == 'end') xOffset = x - tp.width;

        tp.paint(canvas, Offset(xOffset, (height - 7.0) * scaleY - tp.height));
      }
    }

    // Goal line
    if (goal != null && goal!.isFinite) {
      final double gy = calcY(goal!);
      final Paint goalPaint = Paint()
        ..color = palette.yellow
        ..strokeWidth = 1.6;
      _drawDashedLine(
        canvas,
        Offset(pl * scaleX, gy),
        Offset((340.0 - pr) * scaleX, gy),
        goalPaint,
        dashLength: 7.0,
        spaceLength: 4.0,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: fmtNum(goal!),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: palette.yellow,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((340.0 - pr - 2.0) * scaleX - tp.width, gy - tp.height - 2.0));
    }

    // Gradient fill under the curve
    final Path fillPath = Path();
    fillPath.moveTo(calcX(pts[0].t), (height - pb) * scaleY);
    for (final LineChartPoint p in pts) {
      fillPath.lineTo(calcX(p.t), calcY(p.y));
    }
    fillPath.lineTo(calcX(pts.last.t), (height - pb) * scaleY);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final Path strokePath = Path();
    strokePath.moveTo(calcX(pts[0].t), calcY(pts[0].y));
    for (int i = 1; i < pts.length; i++) {
      strokePath.lineTo(calcX(pts[i].t), calcY(pts[i].y));
    }
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(strokePath, linePaint);

    // Marked points
    for (final LineChartPoint p in pts) {
      if (p.m != null) {
        final double r = (2.4 + p.m! * 3.0) * scaleX;
        final Paint markPaint = Paint()
          ..color = color.withValues(alpha: (0.3 + p.m! * 0.7).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(calcX(p.t), calcY(p.y)), r, markPaint);
      }
    }

    // Last point solid dot
    final LineChartPoint lastPt = pts.last;
    final Paint lastDotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(calcX(lastPt.t), calcY(lastPt.y)), 4.0, lastDotPaint);

    // Hover crosshairs & dot
    if (hover != null) {
      final Paint crossPaint = Paint()
        ..color = palette.muted.withValues(alpha: 0.6)
        ..strokeWidth = 1.0;
      _drawDashedLine(
        canvas,
        Offset(hover!.x, pt * scaleY),
        Offset(hover!.x, (height - pb) * scaleY),
        crossPaint,
        dashLength: 3.0,
        spaceLength: 3.0,
      );
      _drawDashedLine(
        canvas,
        Offset(pl * scaleX, hover!.y),
        Offset((340.0 - pr) * scaleX, hover!.y),
        crossPaint,
        dashLength: 3.0,
        spaceLength: 3.0,
      );

      final Paint hoverFill = Paint()..color = color;
      final Paint hoverStroke = Paint()
        ..color = palette.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(hover!.x, hover!.y), 5.0, hoverFill);
      canvas.drawCircle(Offset(hover!.x, hover!.y), 5.0, hoverStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.height != height ||
        oldDelegate.color != color ||
        oldDelegate.goal != goal ||
        oldDelegate.axes != axes ||
        oldDelegate.invert != invert ||
        oldDelegate.hover != hover;
  }
}
