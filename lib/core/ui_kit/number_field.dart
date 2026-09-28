// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';

/// Width of a numeric string in `ch`, matching openGym `numWidthCh`.
double numWidthCh(String s) {
  double w = 0.0;
  for (int i = 0; i < s.length; i++) {
    w += (s[i] == '.' ? 0.5 : 1.0);
  }
  return max(1.0, w);
}

/// Numeric input accepting ',' as decimal point and sanitizing per openGym `NumberField`.
///
/// Keeps a local draft while focused and commits on edit/blur using openGym's commit():
/// - Replaces ',' with '.' and strips all characters except digits and '.'
/// - Enforces single decimal point if [decimal] is true, strips fractional part if false
/// - Empty string maps to null if [nullable] is true, otherwise 0
/// - Negative values become 0 unless [nullable]
/// - Uses [num.tryParse] only (never throws)
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decimal = true,
    this.nullable = false,
    this.fit = false,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final num? value;
  final ValueChanged<num?> onChanged;
  final bool decimal;
  final bool nullable;
  final bool fit;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _draft;
  num? _committed;

  @override
  void initState() {
    super.initState();
    _committed = widget.value;
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draft != null && _committed != widget.value) {
      _draft = null;
      _committed = null;
      _controller.text = _formatValue(widget.value);
    } else if (_draft == null && widget.value != oldWidget.value) {
      _controller.text = _formatValue(widget.value);
    }
  }

  String _formatValue(num? v) {
    if (v == null) return '';
    if (v is int || v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toString();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // Blur commit
      setState(() {
        _draft = null;
        _committed = null;
        _controller.text = _formatValue(widget.value);
      });
    }
  }

  void _commit(String raw) {
    String s = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final int firstDot = s.indexOf('.');
    if (firstDot != -1) {
      if (widget.decimal) {
        final String before = s.substring(0, firstDot + 1);
        final String after = s.substring(firstDot + 1).replaceAll('.', '');
        s = '$before$after';
      } else {
        s = s.substring(0, firstDot);
      }
    }

    num? n;
    if (s.isEmpty || s == '.') {
      n = widget.nullable ? null : 0;
    } else {
      final num? parsed = num.tryParse(s);
      if (parsed == null) {
        n = widget.nullable ? null : 0;
      } else {
        n = widget.nullable ? parsed : max(0, parsed);
      }
    }

    _committed = n;
    _draft = s;
    widget.onChanged(n);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle defaultStyle = TextStyle(
      fontSize: 17.0,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final TextStyle effectiveStyle = defaultStyle.merge(widget.style);

    final Widget field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      textAlign: widget.textAlign,
      style: effectiveStyle,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        isDense: true,
      ),
      cursorColor: palette.acc,
      onChanged: _commit,
    );

    if (widget.fit) {
      final String text = _draft ?? _formatValue(widget.value);
      final double widthInCh = numWidthCh(text.isEmpty ? '0' : text);
      // Average character width at effective font size ~0.6 * fontSize
      final double charWidth = (effectiveStyle.fontSize ?? 17.0) * 0.62;
      return SizedBox(
        width: max(40.0, widthInCh * charWidth + 16.0),
        child: field,
      );
    }

    return field;
  }
}
