// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/number_field.dart';

// Fixed weight range. Matches openGym WeightInput W_LO and wHi(unit).
// See `../openGym/frontend/src/sheets.jsx` lines 170-171.
const double _kWLo = 1.0;
double _kWHi(String unit) => unit == 'lb' ? 660.0 : 300.0;

/// Shared body-weight / load picker matching openGym `WeightInput`.
/// Ports `../openGym/frontend/src/sheets.jsx` lines 172-198.
class WeightInput extends StatelessWidget {
  const WeightInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.unit,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final String unit;

  num _clamp(num x) {
    final double hi = _kWHi(unit);
    final num rounded = (x * 10).round() / 10;
    return rounded < _kWLo ? _kWLo : (rounded > hi ? hi : rounded);
  }

  void _onSlide(num x) => onChanged(_clamp(x));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double hi = _kWHi(unit);
    final double sv = value.toDouble().clamp(_kWLo, hi);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Centered numeric input field with unit (no cramped +/- buttons)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              NumberField(
                value: value,
                decimal: true,
                fit: true,
                style: const TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
                onChanged: (num? v) {
                  if (v != null) onChanged(_clamp(v));
                },
              ),
              const SizedBox(width: 6.0),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        // Quick-step chips: ±0.5 and ±1
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ChipBtn(label: '−1', onTap: () => _onSlide(value - 1)),
            const SizedBox(width: 6.0),
            _ChipBtn(label: '−0.5', onTap: () => _onSlide(value - 0.5)),
            const SizedBox(width: 6.0),
            _ChipBtn(label: '+0.5', onTap: () => _onSlide(value + 0.5)),
            const SizedBox(width: 6.0),
            _ChipBtn(label: '+1', onTap: () => _onSlide(value + 1)),
          ],
        ),
        const SizedBox(height: 12.0),
        // Slider
        AppSlider(
          value: sv,
          min: _kWLo,
          max: hi,
          onChanged: (double v) => _onSlide(v),
        ),
      ],
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: palette.surface3,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
