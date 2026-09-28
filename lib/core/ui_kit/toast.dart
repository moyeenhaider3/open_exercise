// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Shows a floating toast message for 2200 ms, matching openGym `useUI.js` toast.
///
/// Clears any currently showing toast before presenting the new one.
void showToast(BuildContext context, String message) {
  final AppPalette palette = AppPalette.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      duration: const Duration(milliseconds: 2200),
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    ),
  );
}
