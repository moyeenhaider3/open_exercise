// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/models/gym_state.dart';
import '../../../core/theme/accents.dart';

/// The subset of [GymState] the shell needs to render itself: theme mode and
/// accent colour, mapped from openGym's raw `'dark'|'light'|'system'` /
/// accent-key strings (`../openGym/frontend/src/App.jsx:47-48`) to typed
/// Flutter values, with the same fallbacks openGym applies for unknown
/// values (`App.jsx` `resolveTheme`: anything other than `'light'`/`'dark'`
/// -> follow the OS setting; unknown accent -> lime).
final class ThemeSettings extends Equatable {
  const ThemeSettings({required this.themeMode, required this.accentKey});

  final ThemeMode themeMode;
  final String accentKey;

  /// Resolved accent [Color]. [accentKey] is always a valid [kAccents] key
  /// (see [fromState]), so this never throws.
  Color get accent => kAccents[accentKey]!;

  /// Maps [GymState.theme]/[GymState.accent] to typed [ThemeSettings].
  /// A theme other than `'light'`/`'dark'` (including `'system'`, a typo, or
  /// `null` from an explicit null or a wrong-typed value demoted by
  /// `JsonReader`) follows the OS setting, as openGym's `resolveTheme` does.
  /// A missing `theme` key never reaches here as `null`: the `kDefaultState`
  /// overlay fills it with DEF's `'dark'`. An unknown accent falls back to
  /// `'lime'`. Passing `null` (no stored state at all) returns
  /// [ThemeSettings.defaults] (dark/lime, from DEF).
  factory ThemeSettings.fromState(GymState? s) {
    if (s == null) return const ThemeSettings.defaults();
    final String accentKey = s.accent ?? GymState.defaultAccent;
    return ThemeSettings(
      themeMode: _themeModeFromOpenGym(s.theme),
      accentKey: kAccents.containsKey(accentKey) ? accentKey : kDefaultAccentKey,
    );
  }

  /// The shell's boot-time default: dark theme, lime accent
  /// (`GymState.defaultTheme`/`GymState.defaultAccent`).
  const ThemeSettings.defaults()
      : themeMode = ThemeMode.dark,
        accentKey = kDefaultAccentKey;

  /// `App.jsx` `resolveTheme`: only `'light'` and `'dark'` are explicit;
  /// every other value follows the OS (`prefers-color-scheme`).
  static ThemeMode _themeModeFromOpenGym(String? theme) => switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

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
