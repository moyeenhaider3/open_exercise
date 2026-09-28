// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../data/theme_settings.dart';
import 'shell_event.dart';
import 'shell_state.dart';

/// Owns the shell's theme/accent: maps theme/accent from [GymStateCubit]
/// and dispatches any user changes through [GymStateCubit.mutate] (D-04).
///
/// Widgets only ever dispatch [ShellEvent]s (FND-01).
/// All events are processed strictly one at a time via a sequential transformer.
class ShellBloc extends Bloc<ShellEvent, ShellState> {
  ShellBloc({required GymStateCubit gymState})
      // ignore: prefer_initializing_formals
      : _gymState = gymState,
        super(const ShellInitial()) {
    on<ShellEvent>(_onEvent, transformer: _sequential<ShellEvent>());
  }

  final GymStateCubit _gymState;
  StreamSubscription<GymState>? _subscription;

  /// Processes events one at a time: the next event's handler starts only
  /// after the previous one completes.
  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(ShellEvent event, Emitter<ShellState> emit) async {
    switch (event) {
      case ShellStarted():
        await _onStarted(emit);
      case ShellStateUpdated(:final GymState state):
        _onStateUpdated(state, emit);
      case ShellThemeChanged(:final String theme):
        await _onThemeChanged(theme);
      case ShellAccentChanged(:final String accentKey):
        await _onAccentChanged(accentKey);
    }
  }

  Future<void> _onStarted(Emitter<ShellState> emit) async {
    emit(ShellReady(settings: ThemeSettings.fromState(_gymState.state)));
    await _subscription?.cancel();
    _subscription = _gymState.stream.listen((GymState s) {
      add(ShellStateUpdated(s));
    });
  }

  void _onStateUpdated(GymState state, Emitter<ShellState> emit) {
    final ThemeSettings newSettings = ThemeSettings.fromState(state);
    final ShellState current = this.state;
    if (current is! ShellReady || current.settings != newSettings) {
      emit(ShellReady(settings: newSettings));
    }
  }

  Future<void> _onThemeChanged(String theme) async {
    await _gymState.mutate((GymState s) => s.copyWith(theme: theme));
  }

  Future<void> _onAccentChanged(String accentKey) async {
    await _gymState.mutate((GymState s) => s.copyWith(accent: accentKey));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
