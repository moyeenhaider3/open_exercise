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
/// Every [ShellEvent] goes through one handler with a sequential transformer,
/// so events are processed strictly one at a time, in order (bloc's default is
/// concurrent). Changes are written with [GymStateRepository.patchSettings],
/// which updates only the `theme`/`accent` keys in a single transaction and
/// never rewrites the workout/routine/body-weight tables, so a settings change
/// cannot revert another setting or drop a concurrent write to the profile.
///
/// The shell must always boot (T-1-12): an unknown theme follows the OS and an
/// unknown accent falls back to lime (see [ThemeSettings.fromState]), and a [loadState]
/// failure falls back to [GymState.defaults] *for rendering only* rather than
/// leaving the Bloc stuck on [ShellInitial]. That fallback is never written
/// back: if the stored profile cannot be read (or the write fails), the change
/// is reported via [addError] and only shown in the UI, never persisted.
class ShellBloc extends Bloc<ShellEvent, ShellState> {
  // Keeps the public `repository:` param name independent of the private field name.
  ShellBloc({required GymStateRepository repository, this.uid = kLocalGuestUid})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const ShellInitial()) {
    on<ShellEvent>(_onEvent, transformer: _sequential<ShellEvent>());
  }

  final GymStateRepository _repository;
  final String uid;

  /// Processes events one at a time: the next event's handler starts only
  /// after the previous one completes.
  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(ShellEvent event, Emitter<ShellState> emit) => switch (event) {
        ShellStarted() => _onStarted(emit),
        ShellThemeChanged(:final String theme) => _persistChange(emit, theme: theme),
        ShellAccentChanged(:final String accentKey) => _persistChange(emit, accent: accentKey),
      };

  Future<void> _onStarted(Emitter<ShellState> emit) async {
    GymState? stored;
    try {
      stored = await _repository.loadState(uid);
    } catch (e, st) {
      addError(e, st);
    }
    emit(ShellReady(settings: ThemeSettings.fromState(stored ?? GymState.defaults())));
  }

  /// Persists a theme and/or accent change via
  /// [GymStateRepository.patchSettings]. "No stored state yet" starts from
  /// [GymState.defaults], exactly like openGym's DEF. If the patch throws
  /// (unreadable profile, database error) nothing is written: the change is
  /// only emitted to the UI, on top of the settings currently shown.
  Future<void> _persistChange(Emitter<ShellState> emit, {String? theme, String? accent}) async {
    try {
      final Map<String, Object?> doc =
          await _repository.patchSettings(uid, theme: theme, accent: accent);
      emit(ShellReady(settings: ThemeSettings.fromState(GymState.fromJson(doc))));
    } catch (e, st) {
      addError(e, st);
      // copyWith treats an explicit null as "clear", so only pass what is being changed.
      GymState uiOnly = _currentAsState();
      if (theme != null) uiOnly = uiOnly.copyWith(theme: theme);
      if (accent != null) uiOnly = uiOnly.copyWith(accent: accent);
      emit(ShellReady(settings: ThemeSettings.fromState(uiOnly)));
    }
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
