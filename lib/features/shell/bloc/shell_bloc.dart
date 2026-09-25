// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/gym_state_repository.dart';
import '../../../core/models/gym_state.dart';
import '../data/theme_settings.dart';
import 'shell_event.dart';
import 'shell_state.dart';

/// Owns the shell's theme/accent: loads them from [GymStateRepository] at
/// boot and persists any change the user makes. All theme/accent logic
/// lives here; widgets only dispatch [ShellEvent]s (FND-01).
///
/// The shell must always boot (T-1-12): an unknown theme/accent value falls
/// back to dark/lime (see [ThemeSettings.fromState]), and a [loadState]
/// failure falls back to [GymState.defaults] rather than leaving the Bloc
/// stuck on [ShellInitial].
class ShellBloc extends Bloc<ShellEvent, ShellState> {
  // Keeps the public `repository:` param name independent of the private field name.
  ShellBloc({required GymStateRepository repository, this.uid = kLocalGuestUid})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const ShellInitial()) {
    on<ShellStarted>(_onStarted);
    on<ShellThemeChanged>(_onThemeChanged);
    on<ShellAccentChanged>(_onAccentChanged);
  }

  final GymStateRepository _repository;
  final String uid;

  Future<void> _onStarted(ShellStarted event, Emitter<ShellState> emit) async {
    final GymState state = await _loadOrDefaults();
    emit(ShellReady(settings: ThemeSettings.fromState(state)));
  }

  Future<void> _onThemeChanged(ShellThemeChanged event, Emitter<ShellState> emit) async {
    final GymState current = await _loadOrDefaults();
    final GymState next = current.copyWith(theme: event.theme);
    await _repository.saveState(uid, next);
    emit(ShellReady(settings: ThemeSettings.fromState(next)));
  }

  Future<void> _onAccentChanged(ShellAccentChanged event, Emitter<ShellState> emit) async {
    final GymState current = await _loadOrDefaults();
    final GymState next = current.copyWith(accent: event.accentKey);
    await _repository.saveState(uid, next);
    emit(ShellReady(settings: ThemeSettings.fromState(next)));
  }

  /// [GymStateRepository.loadState], or [GymState.defaults] if there is no
  /// stored state yet, or if loading throws for any reason.
  Future<GymState> _loadOrDefaults() async {
    try {
      final GymState? loaded = await _repository.loadState(uid);
      return loaded ?? GymState.defaults();
    } catch (_) {
      return GymState.defaults();
    }
  }
}
