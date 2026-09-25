// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Explicit events for [ShellBloc] (`lib/features/shell/bloc/shell_bloc.dart`).
/// Widgets only ever dispatch these; all theme/accent logic lives in the
/// Bloc (FND-01).
sealed class ShellEvent extends Equatable {
  const ShellEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Dispatched once at app boot to load the persisted theme/accent.
final class ShellStarted extends ShellEvent {
  const ShellStarted();
}

/// The user picked a new theme mode string (openGym's raw
/// `'dark'|'light'|'system'` form).
final class ShellThemeChanged extends ShellEvent {
  const ShellThemeChanged(this.theme);

  final String theme;

  @override
  List<Object?> get props => <Object?>[theme];
}

/// The user picked a new accent key (one of `kAccents`' keys).
final class ShellAccentChanged extends ShellEvent {
  const ShellAccentChanged(this.accentKey);

  final String accentKey;

  @override
  List<Object?> get props => <Object?>[accentKey];
}
