// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase3_models.dart';
import '../../../../core/js/modules/effort_js.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';

/// Opens the effort rating picker sheet.
///
/// [kind] is 'rir' or 'rpe'; [value] is the set's current rating on that scale (or null).
/// [onPick] receives the new value on the same scale, or null to clear.
/// Ports `../openGym/frontend/src/sheets.jsx` EffortPicker lines 1454-1508.
Future<void> showEffortPickerSheet(
  BuildContext context, {
  required String kind,
  num? value,
  required void Function(num?) onPick,
}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _EffortPickerSheet(
      kind: kind,
      initialValue: value,
      onPick: onPick,
    ),
  );
}

class _EffortPickerSheet extends StatefulWidget {
  const _EffortPickerSheet({
    required this.kind,
    required this.initialValue,
    required this.onPick,
  });

  final String kind;
  final num? initialValue;
  final void Function(num?) onPick;

  @override
  State<_EffortPickerSheet> createState() => _EffortPickerSheetState();
}

class _EffortPickerSheetState extends State<_EffortPickerSheet> {
  late num? _v;
  late JsEngineService _engine;

  @override
  void initState() {
    super.initState();
    _v = widget.initialValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engine = context.read<JsEngineService>();
  }

  void _set(num? nv) {
    setState(() => _v = nv);
    widget.onPick(nv);
  }

  void _commit(num? nv) {
    // Commit order matches the source: close, then onPick.
    Navigator.of(context).pop();
    widget.onPick(nv);
  }

  void _pick(num rir) {
    final num? scaled = _engine.effort.toScale(widget.kind, rir);
    _commit(scaled);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<EffortPreset> presets = _engine.effort.presets;
    // Map the current value to RIR for tick comparison (Workout.jsx effortCell curRir).
    final double? curRir = _v != null
        ? _engine.effort.rirOf(
            widget.kind == 'rpe'
                ? SetEntry.fromJson(<String, Object?>{'rpe': _v})
                : SetEntry.fromJson(<String, Object?>{'rir': _v}),
          )
        : null;
    final String? curColor = _engine.effort.effortColor(curRir);

    // The hd (header/display) label for the exact field, from EFFORT[kind].hd.
    final String kind = widget.kind;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('How hard was that set?'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2.0),
        Text(
          t('Tap how many reps you had left, or type an exact {0}.', <Object?>[kind.toUpperCase()]),
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 10.0),
        // Preset rows: same as the ⋯ menu (tinted square with value, feel text, tick).
        ...presets.map((EffortPreset p) {
          final num? scaled = _engine.effort.toScale(kind, p.rir);
          final String label = (scaled != null ? fmtNum(scaled) : '') + (p.tail ? '+' : '');
          final bool on = curRir != null && curRir == p.rir;
          final Color? tint = palette.cssVar(p.color);

          return InkWell(
            onTap: () => _pick(p.rir),
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: tint?.withValues(alpha: 0.16) ?? palette.surface2,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: tint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      t(p.feel),
                      style: const TextStyle(fontSize: 15.0),
                    ),
                  ),
                  if (on) const AppIcon('check', size: 18.0),
                ],
              ),
            ),
          );
        }),
        // Exact value stepper row, tinted like the logged cell.
        const SizedBox(height: 4.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: curColor != null
                ? Color.lerp(palette.cssVar(curColor) ?? Colors.transparent,
                    palette.surface2, 0.8)
                : palette.surface2,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  t('Exact {0}', <Object?>[kind.toUpperCase()]),
                  style: const TextStyle(fontSize: 15.0),
                ),
              ),
              // Decrease
              IconButton(
                icon: const AppIcon('minus', size: 16.0),
                tooltip: t('Decrease'),
                onPressed: () {
                  final double? next = _engine.history.stepEffort(kind, _v, -1);
                  _set(next);
                },
              ),
              SizedBox(
                width: 52.0,
                child: Text(
                  _v != null ? fmtNum(_v!) : '–',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: curColor != null ? palette.cssVar(curColor) : null,
                  ),
                ),
              ),
              // Increase
              IconButton(
                icon: const AppIcon('plus', size: 16.0),
                tooltip: t('Increase'),
                onPressed: () {
                  final double? next = _engine.history.stepEffort(kind, _v, 1);
                  _set(next);
                },
              ),
            ],
          ),
        ),
        if (_v != null) ...<Widget>[
          const SizedBox(height: 10.0),
          AppButton(
            label: Text(t('Clear rating')),
            icon: 'xmark',
            variant: AppButtonVariant.ghost,
            onPressed: () => _commit(null),
          ),
        ],
        const SizedBox(height: 4.0),
      ],
    );
  }
}
