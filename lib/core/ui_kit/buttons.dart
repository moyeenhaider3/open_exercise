// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'icons/app_icon.dart';

enum AppButtonVariant {
  plain,
  primary,
  tinted,
  ghost,
  danger,
}

/// Standard button matching openGym `.btn` styles.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.plain,
    this.small = false,
    this.icon,
    this.trailingIcon,
  });

  final Widget label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool small;
  final String? icon;
  final String? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = palette.acc;
        fg = palette.onAcc;
        border = BorderSide.none;
      case AppButtonVariant.tinted:
        bg = palette.acc.withValues(alpha: 0.16);
        fg = palette.acc;
        border = BorderSide.none;
      case AppButtonVariant.danger:
        bg = palette.red;
        fg = Colors.white;
        border = BorderSide.none;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = Theme.of(context).colorScheme.onSurface;
        border = BorderSide.none;
      case AppButtonVariant.plain:
        bg = palette.surface2;
        fg = Theme.of(context).colorScheme.onSurface;
        border = BorderSide.none;
    }

    final double height = small ? 32.0 : 44.0;
    final EdgeInsets padding = small
        ? const EdgeInsets.symmetric(horizontal: 10.0)
        : const EdgeInsets.symmetric(horizontal: 16.0);

    final Widget content = Row(
      mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          AppIcon(icon!, size: small ? 16.0 : 18.0, color: fg),
          const SizedBox(width: 8.0),
        ],
        Flexible(child: label),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: 8.0),
          AppIcon(trailingIcon!, size: small ? 16.0 : 18.0, color: fg),
        ],
      ],
    );

    final ButtonStyle style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return bg.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.pressed)) {
          return bg.withValues(alpha: 0.85);
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return fg.withValues(alpha: 0.38);
        }
        return fg;
      }),
      side: WidgetStateProperty.all(border),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(
        Size(small ? 0.0 : double.infinity, height),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      elevation: WidgetStateProperty.all(0.0),
    );

    return SizedBox(
      width: small ? null : double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: style,
        child: content,
      ),
    );
  }
}

/// Stand-in for openGym `.iconbtn`.
class AppIconButton extends StatelessWidget {
  const AppIconButton(
    this.icon, {
    super.key,
    this.onPressed,
    this.tooltip,
    this.small = false,
    this.color,
  });

  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool small;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double iconSize = small ? 18.0 : 22.0;
    final double buttonSize = small ? 32.0 : 40.0;

    final Widget button = IconButton(
      onPressed: onPressed,
      iconSize: iconSize,
      icon: AppIcon(icon, size: iconSize, color: color),
      tooltip: tooltip,
      constraints: BoxConstraints.tightFor(width: buttonSize, height: buttonSize),
      padding: EdgeInsets.zero,
    );

    return button;
  }
}
