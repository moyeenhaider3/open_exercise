// SPDX-License-Identifier: AGPL-3.0-or-later

/// Native modal sheets, dialogs, and menu helpers.
///
/// D-05: Replaces openGym useUI openSheet/closeSheet/closeAll and Modals.jsx with
/// native Flutter Navigator APIs (showModalBottomSheet, showDialog).
/// No sheet-stack Bloc.
library;

import 'package:flutter/material.dart';

import '../i18n/t.dart';
import '../theme/app_palette.dart';
import 'buttons.dart';
import 'icons/app_icon.dart';
import 'rows.dart';

/// Opens a bottom sheet matching openGym `.sheet`.
///
/// If [locked] is true (e.g. weigh-in, finish workout), dismissal via swipe,
/// scrim tap, and Android back button is prevented.
Future<T?> showAppSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool locked = false,
}) {
  final AppPalette palette = AppPalette.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    isDismissible: !locked,
    enableDrag: !locked,
    showDragHandle: !locked,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.0)),
    ),
    builder: (BuildContext ctx) {
      return PopScope(
        canPop: !locked,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
            child: SingleChildScrollView(
              child: builder(ctx),
            ),
          ),
        ),
      );
    },
  );
}

/// Opens a centered dialog matching openGym `kind: 'center'`.
Future<T?> showCenterDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool locked = false,
}) {
  final AppPalette palette = AppPalette.of(context);

  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: !locked,
    builder: (BuildContext ctx) {
      return PopScope(
        canPop: !locked,
        child: Dialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 24.0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Shows a confirmation dialog matching openGym `ConfirmDialog`.
Future<bool> showConfirmSheet(
  BuildContext context, {
  String? title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool danger = false,
}) async {
  final bool? result = await showCenterDialog<bool>(
    context,
    (BuildContext ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.0,
              color: AppPalette.of(ctx).muted,
            ),
          ),
          const SizedBox(height: 20.0),
          AppButton(
            label: Text(confirmText ?? t('Confirm')),
            variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 8.0),
          AppButton(
            label: Text(cancelText ?? t('Cancel')),
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Action item for [showMenuSheet].
class MenuItemSpec {
  const MenuItemSpec({
    this.icon,
    required this.label,
    this.sub,
    this.danger = false,
    this.disabled = false,
    required this.onTap,
  });

  final String? icon;
  final String label;
  final String? sub;
  final bool danger;
  final bool disabled;
  final VoidCallback onTap;
}

/// Shows an action menu sheet matching openGym `MenuSheet`.
Future<void> showMenuSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
  required List<MenuItemSpec> items,
}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) {
      final AppPalette palette = AppPalette.of(ctx);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13.0, color: palette.muted),
              ),
            ],
            const SizedBox(height: 12.0),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final MenuItemSpec item = items[index];
              return Opacity(
                opacity: item.disabled ? 0.4 : 1.0,
                child: ListItem(
                  leading: item.icon != null
                      ? AppIcon(
                          item.icon!,
                          size: 20.0,
                          color: item.danger ? palette.red : palette.muted,
                        )
                      : null,
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: item.danger
                          ? palette.red
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: item.sub != null ? Text(item.sub!) : null,
                  onTap: item.disabled
                      ? null
                      : () {
                          // Close sheet first, then execute onTap (matching openGym order).
                          Navigator.of(ctx).pop();
                          item.onTap();
                        },
                ),
              );
            },
          ),
          const SizedBox(height: 8.0),
          AppButton(
            label: Text(t('Cancel')),
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      );
    },
  );
}

/// Closes all active sheets/dialogs up to the underlying page route.
void closeAllSheets(BuildContext context) {
  Navigator.of(context, rootNavigator: true).popUntil(
    (Route<dynamic> r) => r is! PopupRoute,
  );
}
