// SPDX-License-Identifier: AGPL-3.0-or-later

/// Native CustomPainter for rendering body maps with exact openGym color ramps.
///
/// Corresponds to openGym `components/BodyMap.jsx` and `index.css:1182-1230`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_palette.dart';
import 'body_geometry_cache.dart';

enum BodyMapVariant { balance, fatigue, strength }

/// Shading and silhouette colors matching openGym index.css:1201-1230.
abstract final class BodyMapColors {
  /// Base unworked muscle color (--bm-base: color-mix(label 11%, surface)).
  /// Source: index.css:1204.
  static Color base(AppPalette p) => Color.lerp(p.surface, p.label, 0.11)!;

  /// Inert silhouette part color (color-mix(label 18%, surface)).
  /// Source: index.css:1207.
  static Color silhouette(AppPalette p) => Color.lerp(p.surface, p.label, 0.18)!;

  /// Muscle shading color for a given level (0-4) and variant.
  /// Source: index.css:1208-1224.
  static Color muscle(BodyMapVariant v, int level, AppPalette p) {
    final Color b = base(p);
    if (level <= 0) return b;

    switch (v) {
      case BodyMapVariant.balance:
        if (level == 1) return Color.lerp(b, p.acc, 0.32)!;
        if (level == 2) return Color.lerp(b, p.acc, 0.56)!;
        if (level == 3) return Color.lerp(b, p.acc, 0.78)!;
        return p.acc;

      case BodyMapVariant.fatigue:
        if (level == 1) return Color.lerp(b, p.yellow, 0.32)!;
        if (level == 2) return p.yellow;
        if (level == 3) return p.orange;
        return p.red;

      case BodyMapVariant.strength:
        if (level == 1) return Color.lerp(b, p.acc, 0.32)!;
        if (level == 2) return Color.lerp(b, p.acc, 0.56)!;
        if (level == 3) return Color.lerp(b, p.acc, 0.78)!;
        return p.yellow;
    }
  }

  /// Legend square color for a given level and variant.
  /// Source: index.css:1183-1187, 1218-1223.
  static Color legendCell(BodyMapVariant v, int level, AppPalette p) {
    if (level <= 0) return p.surface2;

    if (v == BodyMapVariant.fatigue) {
      if (level >= 4) return p.red;
      if (level == 3) return p.orange;
      if (level == 2) return p.yellow;
      return Color.lerp(p.surface2, p.yellow, 0.30)!;
    }

    if (v == BodyMapVariant.strength && level >= 4) {
      return p.yellow;
    }

    // Default / balance ramp (.hm-c)
    if (level == 1) return Color.lerp(p.surface2, p.acc, 0.30)!;
    if (level == 2) return Color.lerp(p.surface2, p.acc, 0.55)!;
    if (level == 3) return Color.lerp(p.surface2, p.acc, 0.78)!;
    return p.acc;
  }
}

/// Canvas transform and inverse mapping for viewBox-preserving aspect ratio.
final class BodyMapFit {
  BodyMapFit({required this.viewBox, required this.size}) {
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;
    scale = (scaleX < scaleY) ? scaleX : scaleY;
    dx = (size.width - viewBox.width * scale) / 2.0;
    dy = (size.height - viewBox.height * scale) / 2.0;
  }

  final Rect viewBox;
  final Size size;
  late final double scale;
  late final double dx;
  late final double dy;

  void apply(Canvas c) {
    c.translate(dx, dy);
    c.scale(scale, scale);
    c.translate(-viewBox.left, -viewBox.top);
  }

  Offset toViewBox(Offset local) {
    final double unX = (local.dx - dx) / scale + viewBox.left;
    final double unY = (local.dy - dy) / scale + viewBox.top;
    return Offset(unX, unY);
  }
}

/// CustomPainter rendering a single BodyViewGeometry (front or back).
class BodyMapPainter extends CustomPainter {
  BodyMapPainter({
    required this.view,
    required this.levels,
    required this.palette,
    required this.variant,
    this.selected,
  });

  final BodyViewGeometry view;
  final Map<String, int> levels;
  final AppPalette palette;
  final BodyMapVariant variant;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || view.viewBox.isEmpty) return;

    final BodyMapFit fit = BodyMapFit(viewBox: view.viewBox, size: size);

    canvas.save();
    fit.apply(canvas);

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final Color silColor = BodyMapColors.silhouette(palette);
    final Color surfaceColor = palette.surface;
    final Color labelColor = palette.label;

    for (final BodyPart part in view.parts) {
      final bool isMuscle = part.kind == BodyPartKind.muscle;
      final int level = isMuscle ? (levels[part.slug] ?? 0) : 0;
      final Color color = isMuscle
          ? BodyMapColors.muscle(variant, level, palette)
          : silColor;

      // Strength level 4 gold drop-shadow glow (index.css:1222)
      if (isMuscle && variant == BodyMapVariant.strength && level >= 4) {
        final Paint glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = palette.yellow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.75 / fit.scale);
        canvas.drawPath(part.path, glowPaint);
      }

      // Fill path
      fillPaint.color = color;
      canvas.drawPath(part.path, fillPaint);

      // Stroke: selected gets width 7 with label color, otherwise 2.5 with surface color
      // (index.css:1225, 1230)
      final bool isSelected = isMuscle && part.slug == selected;
      if (isSelected) {
        strokePaint.color = labelColor;
        strokePaint.strokeWidth = 7.0;
      } else {
        strokePaint.color = surfaceColor;
        strokePaint.strokeWidth = 2.5;
      }
      canvas.drawPath(part.path, strokePaint);
    }

    canvas.restore();
  }

  /// Hit tests a local tap offset against muscles in reverse paint order (topmost wins).
  static String? hitTestMuscle(BodyViewGeometry view, Size size, Offset local) {
    if (size.isEmpty || view.viewBox.isEmpty) return null;
    final BodyMapFit fit = BodyMapFit(viewBox: view.viewBox, size: size);
    final Offset point = fit.toViewBox(local);

    for (final BodyPart part in view.muscles.toList().reversed) {
      if (part.path.contains(point)) {
        return part.slug;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.view != view ||
        !mapEquals(oldDelegate.levels, levels) ||
        oldDelegate.palette != palette ||
        oldDelegate.variant != variant ||
        oldDelegate.selected != selected;
  }
}
