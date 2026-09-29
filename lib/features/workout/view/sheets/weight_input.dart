// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';

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
    final double hi = _kWHi(unit);
    final double sv = value.toDouble().clamp(_kWLo, hi);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // +/- 0.1 step row + numeric field
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const AppIcon('minus', size: 18.0),
              tooltip: t('−0.1 {0}', <Object?>[unit]),
              onPressed: () => _onSlide(value - 0.1),
            ),
            SizedBox(
              width: 120.0,
              child: AppStepper(
                value: value,
                step: 0.1,
                decimal: true,
                unit: unit,
                onChanged: (num? v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
            IconButton(
              icon: const AppIcon('plus', size: 18.0),
              tooltip: t('+0.1 {0}', <Object?>[unit]),
              onPressed: () => _onSlide(value + 0.1),
            ),
          ],
        ),
        // Quick-step chips: ±0.5 and ±1
        const SizedBox(height: 4.0),
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
        const SizedBox(height: 8.0),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13.0)),
      ),
    );
  }
}
