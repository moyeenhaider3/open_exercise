// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import 'package:flutter/material.dart';

import '../i18n/t.dart';
import '../theme/app_palette.dart';
import 'buttons.dart';
import 'icons/app_icon.dart';
import 'modals.dart';
import 'number_field.dart';
import 'rows.dart';

/// Adaptive toggle switch matching openGym `Switch`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Switch.adaptive(
      value: value,
      onChanged: disabled ? null : onChanged,
      activeThumbColor: palette.onAcc,
      activeTrackColor: palette.acc,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: palette.surface3,
    );
  }
}

/// Option definition for [AppSegmented].
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final String? icon;
}

/// Material 3 SegmentedButton matching openGym `Segmented`.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SegmentedButton<T>(
      segments: options
          .map(
            (SegmentOption<T> o) => ButtonSegment<T>(
              value: o.value,
              label: Text(o.label),
              icon: o.icon != null ? AppIcon(o.icon!, size: 16.0) : null,
            ),
          )
          .toList(),
      selected: <T>{value},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty) {
          onChanged(newSelection.first);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.surface2;
          }
          return palette.surface3;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.onSurface;
          }
          return palette.muted;
        }),
        side: WidgetStateProperty.all(BorderSide.none),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }
}

/// Increment/decrement stepper control wrapping [NumberField].
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    this.step = 1,
    required this.onChanged,
    this.decimal = true,
    this.label,
    this.unit,
    this.invalid = false,
  });

  final num? value;
  final num step;
  final ValueChanged<num?> onChanged;
  final bool decimal;
  final String? label;
  final String? unit;
  final bool invalid;

  void _bump(int dir) {
    final num cur = value ?? 0;
    final num raw = cur + dir * step;
    final num next = dir < 0
        ? max(0, (raw * 100).round() / 100)
        : (raw * 100).round() / 100;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Widget inner = Container(
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10.0),
        border: invalid ? Border.all(color: palette.red, width: 1.0) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => _bump(-1),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(10.0),
            ),
            child: const SizedBox(
              width: 40.0,
              height: 44.0,
              child: Center(child: AppIcon('minus', size: 16.0)),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: NumberField(
                    value: value,
                    decimal: decimal,
                    onChanged: onChanged,
                    fit: true,
                  ),
                ),
                if (unit != null) ...<Widget>[
                  const SizedBox(width: 4.0),
                  Text(
                    unit!,
                    style: TextStyle(fontSize: 13.0, color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: () => _bump(1),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(10.0),
            ),
            child: const SizedBox(
              width: 40.0,
              height: 44.0,
              child: Center(child: AppIcon('plus', size: 16.0)),
            ),
          ),
        ],
      ),
    );

    if (label == null) return inner;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label!,
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 6.0),
        inner,
      ],
    );
  }
}

/// Circular checkbox matching openGym `Check`.
class AppCheck extends StatelessWidget {
  const AppCheck({
    super.key,
    required this.checked,
    required this.onChanged,
    this.size = 24.0,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color bg = checked ? palette.acc : Colors.transparent;
    final Border? border = checked
        ? null
        : Border.all(color: palette.dim, width: 2.0);

    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        child: checked
            ? Center(
                child: AppIcon(
                  'check',
                  size: size * 0.65,
                  color: palette.onAcc,
                ),
              )
            : null,
      ),
    );
  }
}

/// Slider control styled with openGym accent and surfaces.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: palette.acc,
        inactiveTrackColor: palette.surface3,
        thumbColor: Colors.white,
        overlayColor: palette.acc.withValues(alpha: 0.16),
        trackHeight: 6.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13.0),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// Search input field with magnifier icon and clear button.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.onClear,
    this.placeholder,
    this.focusNode,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String? placeholder;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Row(
        children: <Widget>[
          AppIcon('magnifier', size: 18.0, color: palette.muted),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: value,
                  selection: TextSelection.collapsed(offset: value.length),
                ),
              ),
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16.0),
              decoration: InputDecoration(
                hintText: placeholder ?? t('Search'),
                hintStyle: TextStyle(color: palette.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
          if (value.isNotEmpty) ...<Widget>[
            const SizedBox(width: 4.0),
            InkWell(
              onTap: onClear ?? () => onChanged(''),
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: AppIcon('xmark', size: 16.0, color: palette.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Generic option for [SelectRow] and [MultiSelectRow].
class SelectOption<T> {
  const SelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? icon;
}

/// Configuration for option filtering in select sheets.
class SearchConfig<T> {
  const SearchConfig({
    this.placeholder,
    this.label,
    this.emptyLabel,
    this.match,
  });

  final String? placeholder;
  final String? label;
  final String? emptyLabel;
  final bool Function(SelectOption<T> option, String query)? match;
}

/// Option row opening a single-selection sheet matching openGym `SelectRow`.
class SelectRow<T> extends StatelessWidget {
  const SelectRow({
    super.key,
    this.icon,
    this.iconTint,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.sheetTitle,
    this.search,
  });

  final String? icon;
  final Color? iconTint;
  final String title;
  final T value;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? sheetTitle;
  final SearchConfig<T>? search;

  @override
  Widget build(BuildContext context) {
    final SelectOption<T>? cur = options.cast<SelectOption<T>?>().firstWhere(
          (SelectOption<T>? o) => o?.value == value,
          orElse: () => null,
        );
    final String label = cur?.label ?? value.toString();

    return AppRow(
      icon: icon,
      iconTint: iconTint,
      title: Text(title),
      value: Text(label),
      accessory: AppRowAccessory.chevron,
      onTap: () async {
        final T? selected = await showSelectSheet<T>(
          context,
          title: sheetTitle ?? title,
          value: value,
          options: options,
          search: search,
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

/// Option row opening a multiple-selection sheet matching openGym `MultiSelectRow`.
class MultiSelectRow<T> extends StatelessWidget {
  const MultiSelectRow({
    super.key,
    this.icon,
    this.iconTint,
    required this.title,
    required this.values,
    required this.options,
    required this.onToggle,
    this.sheetTitle,
    this.noneLabel,
    this.doneLabel,
  });

  final String? icon;
  final Color? iconTint;
  final String title;
  final List<T> values;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onToggle;
  final String? sheetTitle;
  final String? noneLabel;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final List<SelectOption<T>> selected =
        options.where((SelectOption<T> o) => values.contains(o.value)).toList();
    final String summary = selected.isNotEmpty
        ? selected.map((SelectOption<T> o) => o.label).join(', ')
        : (noneLabel ?? '');

    return AppRow(
      icon: icon,
      iconTint: iconTint,
      title: Text(title),
      value: Text(summary),
      accessory: AppRowAccessory.chevron,
      onTap: () async {
        await showMultiSelectSheet<T>(
          context,
          title: sheetTitle ?? title,
          values: values,
          options: options,
          onToggle: onToggle,
          doneLabel: doneLabel,
        );
      },
    );
  }
}

/// Shows a single-choice bottom sheet for [SelectRow].
Future<T?> showSelectSheet<T>(
  BuildContext context, {
  required String title,
  required T value,
  required List<SelectOption<T>> options,
  SearchConfig<T>? search,
}) {
  return showAppSheet<T>(
    context,
    (BuildContext ctx) {
      return _SelectSheetContent<T>(
        title: title,
        value: value,
        options: options,
        search: search,
      );
    },
  );
}

class _SelectSheetContent<T> extends StatefulWidget {
  const _SelectSheetContent({
    required this.title,
    required this.value,
    required this.options,
    this.search,
  });

  final String title;
  final T value;
  final List<SelectOption<T>> options;
  final SearchConfig<T>? search;

  @override
  State<_SelectSheetContent<T>> createState() => _SelectSheetContentState<T>();
}

class _SelectSheetContentState<T> extends State<_SelectSheetContent<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final List<SelectOption<T>> visible = widget.options.where((SelectOption<T> o) {
      if (_query.trim().isEmpty) return true;
      if (widget.search?.match != null) {
        return widget.search!.match!(o, _query);
      }
      return o.label.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.title,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        if (widget.search != null) ...<Widget>[
          const SizedBox(height: 12.0),
          SearchField(
            value: _query,
            onChanged: (String q) => setState(() => _query = q),
            onClear: () => setState(() => _query = ''),
            placeholder: widget.search?.placeholder,
          ),
        ],
        const SizedBox(height: 12.0),
        if (visible.isEmpty && widget.search != null)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              widget.search?.emptyLabel ?? t('No options found'),
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) {
              final SelectOption<T> o = visible[index];
              final bool isSelected = o.value == widget.value;

              return ListItem(
                title: Text(
                  o.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: o.subtitle != null ? Text(o.subtitle!) : null,
                trailing: isSelected
                    ? AppIcon('check', size: 18.0, color: palette.acc)
                    : null,
                onTap: () => Navigator.of(context).pop(o.value),
              );
            },
          ),
      ],
    );
  }
}

/// Shows a multi-choice bottom sheet for [MultiSelectRow].
Future<void> showMultiSelectSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required List<SelectOption<T>> options,
  required ValueChanged<T> onToggle,
  String? doneLabel,
}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) {
      return _MultiSelectSheetContent<T>(
        title: title,
        values: values,
        options: options,
        onToggle: onToggle,
        doneLabel: doneLabel,
      );
    },
  );
}

class _MultiSelectSheetContent<T> extends StatefulWidget {
  const _MultiSelectSheetContent({
    required this.title,
    required this.values,
    required this.options,
    required this.onToggle,
    this.doneLabel,
  });

  final String title;
  final List<T> values;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onToggle;
  final String? doneLabel;

  @override
  State<_MultiSelectSheetContent<T>> createState() =>
      _MultiSelectSheetContentState<T>();
}

class _MultiSelectSheetContentState<T> extends State<_MultiSelectSheetContent<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.values.toSet();
  }

  void _toggle(T val) {
    setState(() {
      if (_selected.contains(val)) {
        _selected.remove(val);
      } else {
        _selected.add(val);
      }
    });
    widget.onToggle(val);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.title,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.options.length,
          itemBuilder: (BuildContext context, int index) {
            final SelectOption<T> o = widget.options[index];
            final bool isSelected = _selected.contains(o.value);

            return ListItem(
              title: Text(
                o.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              subtitle: o.subtitle != null ? Text(o.subtitle!) : null,
              trailing: isSelected
                  ? AppIcon('check', size: 18.0, color: palette.acc)
                  : null,
              onTap: () => _toggle(o.value),
            );
          },
        ),
        const SizedBox(height: 16.0),
        AppButton(
          label: Text(widget.doneLabel ?? t('Done')),
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
