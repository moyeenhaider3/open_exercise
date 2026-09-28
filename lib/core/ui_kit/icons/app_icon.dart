// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'app_icon_data.g.dart';

/// Pre-parsed cached paths for an icon.
final class _CachedIconElement {
  const _CachedIconElement({
    required this.path,
    required this.isFill,
    required this.isStroke,
    this.opacity,
  });

  final Path path;
  final bool isFill;
  final bool isStroke;
  final double? opacity;
}

final Map<String, List<_CachedIconElement>> _parsedPathCache =
    <String, List<_CachedIconElement>>{};

List<_CachedIconElement>? _resolveElements(String name) {
  final List<_CachedIconElement>? cached = _parsedPathCache[name];
  if (cached != null) return cached;

  final List<IconElement>? rawElements = kIconData[name];
  if (rawElements == null) return null;

  final List<_CachedIconElement> list = <_CachedIconElement>[];
  for (final IconElement el in rawElements) {
    final Path path = Path();
    switch (el.type) {
      case IconElementType.path:
        if (el.d != null && el.d!.isNotEmpty) {
          path.addPath(parseSvgPathData(el.d!), Offset.zero);
        }
      case IconElementType.rect:
        final double x = el.x ?? 0.0;
        final double y = el.y ?? 0.0;
        final double w = el.width ?? 0.0;
        final double h = el.height ?? 0.0;
        final double rx = el.rx ?? 0.0;
        if (rx > 0) {
          path.addRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rx)),
          );
        } else {
          path.addRect(Rect.fromLTWH(x, y, w, h));
        }
      case IconElementType.circle:
        final double cx = el.cx ?? 0.0;
        final double cy = el.cy ?? 0.0;
        final double r = el.r ?? 0.0;
        path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case IconElementType.ellipse:
        final double cx = el.cx ?? 0.0;
        final double cy = el.cy ?? 0.0;
        final double rx = el.rx ?? 0.0;
        final double ry = el.r ?? 0.0;
        path.addOval(Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2));
      case IconElementType.line:
      case IconElementType.polyline:
      case IconElementType.polygon:
        // Not used by openGym Icon.jsx, but handled gracefully.
        break;
    }

    final bool isFill = el.fill == 'currentColor';
    final bool isStroke = el.stroke != 'none';

    list.add(
      _CachedIconElement(
        path: path,
        isFill: isFill,
        isStroke: isStroke,
        opacity: el.opacity,
      ),
    );
  }

  _parsedPathCache[name] = list;
  return list;
}

/// openGym icon component rendered from SVG path data using [parseSvgPathData].
///
/// Uses an ambient 24x24 viewBox, stroke-width 1.7 (or [strokeWidth]),
/// [StrokeCap.round], and [StrokeJoin.round].
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  /// Name of the icon (matches keys in [kIconData]).
  final String name;

  /// Optical size in logical pixels (defaults to ambient [IconTheme.size] or 24.0).
  final double? size;

  /// Stroke/fill color (defaults to ambient [IconTheme.color] or black).
  final Color? color;

  /// Custom stroke width (defaults to openGym standard 1.7).
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIconData.containsKey(name)) {
      return const SizedBox.shrink();
    }

    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size ?? 24.0;
    final Color iconColor = color ?? iconTheme.color ?? const Color(0xFF000000);

    return ExcludeSemantics(
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: CustomPaint(
          size: Size(iconSize, iconSize),
          painter: _AppIconPainter(
            name: name,
            color: iconColor,
            strokeWidth: strokeWidth ?? 1.7,
          ),
        ),
      ),
    );
  }
}

final class _AppIconPainter extends CustomPainter {
  const _AppIconPainter({
    required this.name,
    required this.color,
    required this.strokeWidth,
  });

  final String name;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final List<_CachedIconElement>? elements = _resolveElements(name);
    if (elements == null || elements.isEmpty) return;

    canvas.save();
    // Scale standard 24x24 viewBox to widget size.
    final double scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;

    for (final _CachedIconElement el in elements) {
      Color c = color;
      if (el.opacity != null && el.opacity! < 1.0) {
        c = c.withValues(alpha: c.a * el.opacity!);
      }

      if (el.isFill) {
        fillPaint.color = c;
        canvas.drawPath(el.path, fillPaint);
      }
      if (el.isStroke) {
        strokePaint.color = c;
        canvas.drawPath(el.path, strokePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
