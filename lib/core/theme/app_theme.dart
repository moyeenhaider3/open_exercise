// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Background colours openGym uses for its dark/light shells
/// (`../openGym/frontend/src/App.jsx:57`).
const Color kDarkBackground = Color(0xFF000000);
const Color kLightBackground = Color(0xFFF2F2F7);

/// Builds a Material 3 [ThemeData] for [brightness] seeded with [accent],
/// matching openGym's dark/light background colours.
ThemeData buildAppTheme(Brightness brightness, Color accent) {
  final bool isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(primary: accent),
    scaffoldBackgroundColor: isDark ? kDarkBackground : kLightBackground,
    extensions: <ThemeExtension<dynamic>>[
      isDark ? AppPalette.dark(accent) : AppPalette.light(accent),
    ],
  );
}
