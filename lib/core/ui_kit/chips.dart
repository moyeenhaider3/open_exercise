// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'icons/app_icon.dart';

/// Specification for one chip in a [ChipStrip].
class ChipItem<T> {
  const ChipItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final String? icon;
}

/// Horizontal scrolling strip of selectable chips matching openGym `.chip` / `.chip.on`.
///
/// Automatically scrolls the active chip into view on selection change,
/// mirroring openGym's `useRevealActiveChip`.
class ChipStrip<T> extends StatefulWidget {
  const ChipStrip({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.noCap = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
  });

  final List<ChipItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool noCap;
  final EdgeInsetsGeometry padding;

  @override
  State<ChipStrip<T>> createState() => _ChipStripState<T>();
}

class _ChipStripState<T> extends State<ChipStrip<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ChipStrip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _revealActive();
    }
  }

  void _revealActive() {
    final int idx =
        widget.items.indexWhere((ChipItem<T> it) => it.value == widget.selected);
    if (idx < 0 || !_scrollController.hasClients) return;

    // Approximate chip width: 80px + padding
    final double targetOffset = (idx * 84.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      height: 48.0,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final ChipItem<T> item = widget.items[index];
          final bool isSelected = item.value == widget.selected;

          final Color bg = isSelected ? palette.acc : palette.surface2;
          final Color fg = isSelected
              ? palette.onAcc
              : Theme.of(context).colorScheme.onSurface;

          final String text = widget.noCap
              ? item.label
              : (item.label.isNotEmpty
                  ? '${item.label[0].toUpperCase()}${item.label.substring(1)}'
                  : '');

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSelected(item.value),
                borderRadius: BorderRadius.circular(99.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(99.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (item.icon != null) ...<Widget>[
                        AppIcon(item.icon!, size: 16.0, color: fg),
                        const SizedBox(width: 6.0),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
