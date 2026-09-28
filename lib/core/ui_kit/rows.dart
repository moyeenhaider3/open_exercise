// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'icons/app_icon.dart';

/// One item row matching openGym `.item`.
class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.disabled = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 12.0),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: disabled
                        ? palette.muted
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: title,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2.0),
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 13.0,
                      color: palette.muted,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8.0),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null || disabled) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: content,
    );
  }
}

enum AppRowAccessory {
  none,
  chevron,
}

/// Settings and form row matching openGym `ui.jsx` Row.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTint,
    this.value,
    this.accessory = AppRowAccessory.none,
    this.danger = false,
    this.child,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final String? icon;
  final Color? iconTint;
  final Widget? value;
  final AppRowAccessory accessory;
  final bool danger;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color textColor =
        danger ? palette.red : Theme.of(context).colorScheme.onSurface;

    final Widget rowContent = Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          AppIcon(
            icon!,
            size: 20.0,
            color: iconTint ?? (danger ? palette.red : palette.muted),
          ),
          const SizedBox(width: 12.0),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                child: title,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2.0),
                DefaultTextStyle(
                  style: TextStyle(fontSize: 13.0, color: palette.muted),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (value != null) ...<Widget>[
          const SizedBox(width: 8.0),
          DefaultTextStyle(
            style: TextStyle(fontSize: 15.0, color: palette.muted),
            child: value!,
          ),
        ],
        if (child != null) ...<Widget>[
          const SizedBox(width: 8.0),
          child!,
        ],
        if (accessory == AppRowAccessory.chevron) ...<Widget>[
          const SizedBox(width: 6.0),
          AppIcon('chevronRight', size: 16.0, color: palette.dim),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: rowContent,
      ),
    );
  }
}

/// Section title matching openGym `h4.sec`.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14.0, 18.0, 14.0, 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: palette.muted,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Screen header matching openGym `.hdr`.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14.0, color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Card container matching openGym `.card`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.accentBorder = false,
    this.padding = const EdgeInsets.all(14.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
    this.onTap,
  });

  final Widget child;
  final bool accentBorder;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Border? border = accentBorder
        ? Border.all(color: palette.acc.withValues(alpha: 0.38), width: 1.0)
        : null;

    final Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: card,
    );
  }
}

/// Tag chip matching openGym `.tag` and `.tag.acc`.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.isAccent = false,
    this.icon,
    this.color,
  });

  final String label;
  final bool isAccent;
  final String? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Color effectiveColor =
        color ?? (isAccent ? palette.acc : palette.muted);
    final Color bg = isAccent
        ? palette.acc.withValues(alpha: 0.16)
        : palette.surface2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            AppIcon(icon!, size: 12.0, color: effectiveColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state display matching openGym `.empty`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = 'figureStrength',
    required this.text,
    this.action,
  });

  final String icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: palette.surface2,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(icon, size: 32.0, color: palette.muted),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.0,
                color: palette.muted,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 16.0),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
