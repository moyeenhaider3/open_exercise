// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

/// ThemeExtension mapping openGym CSS variables to Flutter colors.
///
/// Supports dark and light theme palettes, dynamic accent selection,
/// and resolving `var(--x)` CSS variable tokens.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.acc,
    required this.acc2,
    required this.onAcc,
    required this.red,
    required this.orange,
    required this.yellow,
    required this.green,
    required this.purple,
    required this.blue,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.sep,
    required this.muted,
    required this.dim,
    required this.label,
  });

  final Color acc;
  final Color acc2;
  final Color onAcc;
  final Color red;
  final Color orange;
  final Color yellow;
  final Color green;
  final Color purple;
  final Color blue;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color sep;
  final Color muted;
  final Color dim;
  final Color label;

  static Color _onAccent(Color accent) {
    // Contrast rules from openGym index.css:98-109
    final int val = accent.toARGB32();
    if (val == 0xFF0A84FF || // sky
        val == 0xFF007AFF ||
        val == 0xFFBF5AF2 || // violet
        val == 0xFFAF52DE ||
        val == 0xFFFF375F || // pink
        val == 0xFFFF2D55 ||
        val == 0xFFFF453A || // red
        val == 0xFFFF3B30) {
      return Colors.white;
    }
    return Colors.black;
  }

  factory AppPalette.dark(Color accent) {
    return AppPalette(
      acc: accent,
      acc2: const Color(0xFF248A3D),
      onAcc: _onAccent(accent),
      red: const Color(0xFFFF453A),
      orange: const Color(0xFFFF9F0A),
      yellow: const Color(0xFFFFD60A),
      green: const Color(0xFF30D158),
      purple: const Color(0xFFBF5AF2),
      blue: const Color(0xFF0A84FF),
      surface: const Color(0xFF1C1C1E),
      surface2: const Color(0xFF2C2C2E),
      surface3: const Color(0xFF3A3A3C),
      sep: const Color(0x99545458),
      muted: const Color(0x99EBEBF5),
      dim: const Color(0x52EBEBF5),
      label: const Color(0xFFFFFFFF),
    );
  }

  factory AppPalette.light(Color accent) {
    return AppPalette(
      acc: accent,
      acc2: const Color(0xFF248A3D),
      onAcc: _onAccent(accent),
      red: const Color(0xFFFF3B30),
      orange: const Color(0xFFFF9500),
      yellow: const Color(0xFFFFCC00),
      green: const Color(0xFF34C759),
      purple: const Color(0xFFAF52DE),
      blue: const Color(0xFF007AFF),
      surface: const Color(0xFFFFFFFF),
      surface2: const Color(0xFFECECEF),
      surface3: const Color(0xFFE3E3E8),
      sep: const Color(0x4A3C3C43),
      muted: const Color(0x993C3C43),
      dim: const Color(0x4D3C3C43),
      label: const Color(0xFF000000),
    );
  }

  static AppPalette of(BuildContext context) {
    final AppPalette? ext = Theme.of(context).extension<AppPalette>();
    return ext ?? AppPalette.dark(const Color(0xFF30D158));
  }

  /// Resolves an openGym CSS variable token like `var(--red)` or `--red` to a [Color].
  Color? cssVar(String token) {
    String clean = token.trim();
    if (clean.startsWith('var(') && clean.endsWith(')')) {
      clean = clean.substring(4, clean.length - 1).trim();
    }
    if (!clean.startsWith('--')) {
      clean = '--$clean';
    }

    switch (clean) {
      case '--acc':
        return acc;
      case '--acc-2':
        return acc2;
      case '--red':
        return red;
      case '--orange':
        return orange;
      case '--yellow':
        return yellow;
      case '--green':
        return green;
      case '--purple':
        return purple;
      case '--blue':
        return blue;
      case '--surface':
        return surface;
      case '--surface-2':
        return surface2;
      case '--surface-3':
        return surface3;
      case '--sep':
        return sep;
      case '--muted':
      case '--label-2':
        return muted;
      case '--dim':
      case '--label-3':
        return dim;
      case '--label':
        return label;
      default:
        return null;
    }
  }

  @override
  AppPalette copyWith({
    Color? acc,
    Color? acc2,
    Color? onAcc,
    Color? red,
    Color? orange,
    Color? yellow,
    Color? green,
    Color? purple,
    Color? blue,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? sep,
    Color? muted,
    Color? dim,
    Color? label,
  }) {
    return AppPalette(
      acc: acc ?? this.acc,
      acc2: acc2 ?? this.acc2,
      onAcc: onAcc ?? this.onAcc,
      red: red ?? this.red,
      orange: orange ?? this.orange,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      purple: purple ?? this.purple,
      blue: blue ?? this.blue,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      sep: sep ?? this.sep,
      muted: muted ?? this.muted,
      dim: dim ?? this.dim,
      label: label ?? this.label,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      acc: Color.lerp(acc, other.acc, t) ?? acc,
      acc2: Color.lerp(acc2, other.acc2, t) ?? acc2,
      onAcc: Color.lerp(onAcc, other.onAcc, t) ?? onAcc,
      red: Color.lerp(red, other.red, t) ?? red,
      orange: Color.lerp(orange, other.orange, t) ?? orange,
      yellow: Color.lerp(yellow, other.yellow, t) ?? yellow,
      green: Color.lerp(green, other.green, t) ?? green,
      purple: Color.lerp(purple, other.purple, t) ?? purple,
      blue: Color.lerp(blue, other.blue, t) ?? blue,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surface2: Color.lerp(surface2, other.surface2, t) ?? surface2,
      surface3: Color.lerp(surface3, other.surface3, t) ?? surface3,
      sep: Color.lerp(sep, other.sep, t) ?? sep,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      dim: Color.lerp(dim, other.dim, t) ?? dim,
      label: Color.lerp(label, other.label, t) ?? label,
    );
  }
}
