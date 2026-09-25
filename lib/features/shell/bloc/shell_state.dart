// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../data/theme_settings.dart';

/// Sealed states for [ShellBloc] (`lib/features/shell/bloc/shell_bloc.dart`).
sealed class ShellState extends Equatable {
  const ShellState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Emitted before [ShellStarted] is handled: nothing has been loaded yet.
final class ShellInitial extends ShellState {
  const ShellInitial();
}

/// The shell is ready to render: a resolved theme mode + accent, always
/// present (falls back to defaults rather than ever being unset -- the
/// shell must always boot, see T-1-12).
final class ShellReady extends ShellState {
  const ShellReady({required this.settings});

  final ThemeSettings settings;

  ThemeMode get themeMode => settings.themeMode;
  String get accentKey => settings.accentKey;
  Color get accent => settings.accent;

  @override
  List<Object?> get props => <Object?>[settings];
}
