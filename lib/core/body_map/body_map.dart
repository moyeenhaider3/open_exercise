// SPDX-License-Identifier: AGPL-3.0-or-later

/// Reusable native BodyMap widget and legend replicating openGym's BodyMap.jsx.
///
/// Shading levels come from callers via the JS engine (MusclesJs / MuscleViewJs).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../format/format.dart';
import '../i18n/t.dart';
import '../js/js_engine_service.dart';
import '../js/modules/muscles_js.dart';
import '../theme/app_palette.dart';
import 'body_geometry_cache.dart';
import 'body_map_painter.dart';

export 'body_geometry_cache.dart';
export 'body_map_painter.dart';

/// Renders paired front and back body views with level-based shading and tap hit-testing.
class BodyMap extends StatefulWidget {
  const BodyMap({
    super.key,
    required this.body,
    this.levels = const <String, int>{},
    this.variant = BodyMapVariant.balance,
    this.selected,
    this.onMuscle,
  });

  final String? body;
  final Map<String, int> levels;
  final BodyMapVariant variant;
  final String? selected;
  final ValueChanged<String>? onMuscle;

  @override
  State<BodyMap> createState() => _BodyMapState();
}

class _BodyMapState extends State<BodyMap> {
  BodyGeometry? _geometry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _geometry ??= BodyGeometryCache.instance.peek(widget.body);
    if (_geometry == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant BodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.body != oldWidget.body) {
      _geometry = BodyGeometryCache.instance.peek(widget.body);
      if (_geometry == null) {
        _load();
      }
    }
  }

  void _load() {
    final AssetBundle bundle = DefaultAssetBundle.of(context);
    BodyGeometryCache.instance.load(bundle, widget.body).then((BodyGeometry g) {
      if (mounted) {
        setState(() => _geometry = g);
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final BodyGeometry? g = _geometry;
    if (g == null) {
      return const SizedBox(height: 200);
    }

    final AppPalette palette = AppPalette.of(context);
    final double screenH = MediaQuery.sizeOf(context).height;
    final double maxViewH = (screenH * 0.46 < 340.0) ? screenH * 0.46 : 340.0;

    Map<String, String>? muscleNameMap;
    if (widget.onMuscle != null) {
      try {
        muscleNameMap = context.read<JsEngineService>().muscles.muscleName;
      } catch (_) {}
    }

    Widget buildView(BodyViewGeometry view) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double propH = w * view.viewBox.height / view.viewBox.width;
          final double h = (propH < maxViewH) ? propH : maxViewH;
          final Size size = Size(w, h);

          Widget child = SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              painter: BodyMapPainter(
                view: view,
                levels: widget.levels,
                palette: palette,
                variant: widget.variant,
                selected: widget.selected,
              ),
            ),
          );

          if (widget.onMuscle != null) {
            child = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails d) {
                final String? slug = BodyMapPainter.hitTestMuscle(view, size, d.localPosition);
                if (slug != null) {
                  widget.onMuscle!(slug);
                }
              },
              child: child,
            );

            final String names = view.muscles
                .map((BodyPart p) => muscleNameMap?[p.slug] ?? p.slug)
                .toSet()
                .join(', ');
            child = Semantics(
              container: true,
              label: names,
              child: child,
            );
          }

          return child;
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: buildView(g.front)),
        const SizedBox(width: 6),
        Expanded(child: buildView(g.back)),
      ],
    );
  }
}

/// Shading legend for balance, fatigue, or strength body maps.
///
/// Mirrors openGym `components/BodyMap.jsx` (BodyMapLegend) and `Stats.jsx:80-93`.
class BodyMapLegend extends StatelessWidget {
  const BodyMapLegend({
    super.key,
    this.variant = BodyMapVariant.balance,
    this.strengthFloor,
  }) : assert(
          variant != BodyMapVariant.strength || strengthFloor != null,
          'strengthFloor is required for strength legend',
        );

  final BodyMapVariant variant;
  final double? strengthFloor;

  Widget _box(int level, AppPalette palette) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: BodyMapColors.legendCell(variant, level, palette),
          borderRadius: BorderRadius.circular(3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final List<Widget> children = <Widget>[];

    switch (variant) {
      case BodyMapVariant.balance:
        children.addAll(<Widget>[
          Text(t('Less'), style: TextStyle(fontSize: 11, color: palette.dim)),
          const SizedBox(width: 4),
          _box(0, palette),
          const SizedBox(width: 4),
          _box(1, palette),
          const SizedBox(width: 4),
          _box(2, palette),
          const SizedBox(width: 4),
          _box(3, palette),
          const SizedBox(width: 4),
          _box(4, palette),
          const SizedBox(width: 4),
          Text(t('More'), style: TextStyle(fontSize: 11, color: palette.dim)),
        ]);

      case BodyMapVariant.fatigue:
        children.addAll(<Widget>[
          Text(t('Fatigued'), style: TextStyle(fontSize: 11, color: palette.dim)),
          const SizedBox(width: 4),
          _box(4, palette),
          const SizedBox(width: 4),
          Text(t('Recovering'), style: TextStyle(fontSize: 11, color: palette.dim)),
          const SizedBox(width: 4),
          _box(2, palette),
          const SizedBox(width: 4),
          Text(t('Ready'), style: TextStyle(fontSize: 11, color: palette.dim)),
          const SizedBox(width: 4),
          _box(0, palette),
        ]);

      case BodyMapVariant.strength:
        children.addAll(<Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '1 ', style: TextStyle(fontSize: 11, color: palette.muted)),
                TextSpan(text: t('full'), style: TextStyle(fontSize: 11, color: palette.dim)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _box(4, palette),
          const SizedBox(width: 4),
          _box(3, palette),
          const SizedBox(width: 4),
          _box(2, palette),
          const SizedBox(width: 4),
          _box(1, palette),
          const SizedBox(width: 4),
          _box(0, palette),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '${fmtNum(strengthFloor!)} ',
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
                TextSpan(text: t('floor'), style: TextStyle(fontSize: 11, color: palette.dim)),
              ],
            ),
          ),
        ]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}
