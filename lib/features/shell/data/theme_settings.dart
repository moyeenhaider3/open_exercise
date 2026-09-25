// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/models/gym_state.dart';
import '../../../core/theme/accents.dart';

/// The subset of [GymState] the shell needs to render itself: theme mode and
/// accent colour, mapped from openGym's raw `'dark'|'light'|'system'` /
/// accent-key strings (`../openGym/frontend/src/App.jsx:47-48`) to typed
/// Flutter values, with the same fallbacks openGym applies for unknown
/// values (unknown theme -> dark, unknown accent -> lime).
final class ThemeSettings extends Equatable {
  const ThemeSettings({required this.themeMode, required this.accentKey});

  final ThemeMode themeMode;
  final String accentKey;

  /// Resolved accent [Color]. [accentKey] is always a valid [kAccents] key
  /// (see [fromState]), so this never throws.
  Color get accent => kAccents[accentKey]!;

  /// Maps [GymState.theme]/[GymState.accent] to typed [ThemeSettings],
  /// falling back to openGym's own defaults
  /// (`GymState.defaultTheme` == `'dark'`, `GymState.defaultAccent` ==
  /// `'lime'`) for a missing or unrecognised value. Passing `null` (no
  /// stored state at all) returns [ThemeSettings.defaults].
  factory ThemeSettings.fromState(GymState? s) {
    final String theme = s?.theme ?? GymState.defaultTheme;
    final String accentKey = s?.accent ?? GymState.defaultAccent;
    return ThemeSettings(
      themeMode: _themeModeFromOpenGym(theme),
      accentKey: kAccents.containsKey(accentKey) ? accentKey : kDefaultAccentKey,
    );
  }

  /// The shell's boot-time default: dark theme, lime accent
  /// (`GymState.defaultTheme`/`GymState.defaultAccent`).
  const ThemeSettings.defaults()
      : themeMode = ThemeMode.dark,
        accentKey = kDefaultAccentKey;

  static ThemeMode _themeModeFromOpenGym(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  /// Inverse of [_themeModeFromOpenGym], for persisting a [ThemeMode] back
  /// into [GymState.theme]'s `'dark'|'light'|'system'` string form.
  static String themeModeToOpenGym(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  @override
  List<Object?> get props => <Object?>[themeMode, accentKey];
}
