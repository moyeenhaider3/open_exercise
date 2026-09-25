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
/// failure falls back to [GymState.defaults] *for rendering only* rather than
/// leaving the Bloc stuck on [ShellInitial].
///
/// That defaults fallback is never written back: [GymStateRepository.saveState]
/// replaces every row for the uid (workouts, routines, body weight), so saving
/// a document built from a failed load would wipe the user's profile. After a
/// failed load a theme/accent change is shown in the UI but not persisted.
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
    GymState? stored;
    try {
      stored = await _repository.loadState(uid);
    } catch (e, st) {
      addError(e, st);
    }
    emit(ShellReady(settings: ThemeSettings.fromState(stored ?? GymState.defaults())));
  }

  Future<void> _onThemeChanged(ShellThemeChanged event, Emitter<ShellState> emit) =>
      _persistChange(emit, (GymState s) => s.copyWith(theme: event.theme));

  Future<void> _onAccentChanged(ShellAccentChanged event, Emitter<ShellState> emit) =>
      _persistChange(emit, (GymState s) => s.copyWith(accent: event.accentKey));

  /// Loads the stored profile, applies [change] and saves it. "No stored state
  /// yet" (`null`) starts from [GymState.defaults], exactly like openGym's DEF.
  /// A load that *throws* is different: the change is only emitted to the UI
  /// (on top of the current settings), and nothing is saved.
  Future<void> _persistChange(
    Emitter<ShellState> emit,
    GymState Function(GymState) change,
  ) async {
    final GymState? stored;
    try {
      stored = await _repository.loadState(uid);
    } catch (e, st) {
      addError(e, st);
      emit(ShellReady(settings: ThemeSettings.fromState(change(_currentAsState()))));
      return;
    }
    final GymState next = change(stored ?? GymState.defaults());
    await _repository.saveState(uid, next);
    emit(ShellReady(settings: ThemeSettings.fromState(next)));
  }

  /// The currently shown settings as a (never persisted) [GymState], so a
  /// UI-only change keeps the other setting as the user currently sees it.
  GymState _currentAsState() {
    final ShellState s = state;
    if (s is! ShellReady) return GymState.defaults();
    return GymState.defaults().copyWith(
      theme: ThemeSettings.themeModeToOpenGym(s.themeMode),
      accent: s.accentKey,
    );
  }
}
