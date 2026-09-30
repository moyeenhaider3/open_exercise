// SPDX-License-Identifier: AGPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'bodyweight_event.dart';
import 'bodyweight_state.dart';

/// BLoC managing bodyweight logging and target weight mutations.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Mirrors `../openGym/frontend/src/sheets.jsx` lines 200-257 & 550-575.
class BodyweightBloc extends Bloc<BodyweightEvent, BodyweightState> {
  BodyweightBloc({
    required GymStateCubit gymState,
  })  : _gymState = gymState,
        super(const BodyweightState()) {
    on<BodyweightEvent>(_onEvent, transformer: _sequential<BodyweightEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(BodyweightGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  StreamSubscription<GymState>? _subscription;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  void _emitSignal(BodyweightSignal sig, Emitter<BodyweightState> emit) {
    emit(state.withSignal(sig));
  }

  Future<void> _onEvent(BodyweightEvent event, Emitter<BodyweightState> emit) async {
    switch (event) {
      case BodyweightGymStateChanged():
        // BodyweightState currently only holds one-shot signals.
        break;
      case BodyweightLogged(:final num value):
        await _onLogged(value, emit);
      case BodyweightEntryDeleted(:final String d):
        await _onEntryDeleted(d);
      case BodyweightGoalSet(:final num value):
        await _onGoalSet(value, emit);
      case BodyweightGoalRemoved():
        await _onGoalRemoved(emit);
    }
  }

  /// Ported from ../openGym/frontend/src/sheets.jsx:203-213 BwSheet.save.
  Future<void> _onLogged(num value, Emitter<BodyweightState> emit) async {
    final num n = (value * 10).round() / 10.0;
    if (n <= 0) {
      _emitSignal(const BodyweightInvalid(), emit);
      return;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String today = todayIso();

    await _gymState.mutate((GymState s) {
      final List<BodyweightEntry> nextBw = s.bodyweight != null
          ? List<BodyweightEntry>.from(s.bodyweight!)
          : <BodyweightEntry>[];
      final int existingIdx = nextBw.indexWhere((BodyweightEntry b) => b.d == today);
      final BodyweightEntry entry = BodyweightEntry(
        d: today,
        w: n,
        t: now,
      );
      if (existingIdx >= 0) {
        nextBw[existingIdx] = entry;
      } else {
        nextBw.add(entry);
      }
      nextBw.sort((BodyweightEntry a, BodyweightEntry b) => (a.d ?? '').compareTo(b.d ?? ''));

      return s.copyWith(bodyweight: nextBw);
    });

    _emitSignal(BodyweightSaved(n), emit);
  }

  /// Ported from ../openGym/frontend/src/sheets.jsx:217 delEntry.
  Future<void> _onEntryDeleted(String d) async {
    await _gymState.mutate((GymState s) {
      if (s.bodyweight == null) return s;
      final List<BodyweightEntry> nextBw =
          s.bodyweight!.where((BodyweightEntry b) => b.d != d).toList();
      return s.copyWith(bodyweight: nextBw);
    });
  }

  /// Ported from ../openGym/frontend/src/sheets.jsx:563-568 GoalSheet.
  Future<void> _onGoalSet(num value, Emitter<BodyweightState> emit) async {
    final num n = (value * 10).round() / 10.0;
    if (n <= 0) {
      _emitSignal(const BodyweightInvalid(), emit);
      return;
    }
    await _gymState.mutate((GymState s) {
      return s.copyWith(targetW: n);
    });
    _emitSignal(BodyweightGoalSaved(n), emit);
  }

  /// Ported from ../openGym/frontend/src/sheets.jsx:571 GoalSheet.
  Future<void> _onGoalRemoved(Emitter<BodyweightState> emit) async {
    await _gymState.mutate((GymState s) {
      return s.copyWith(targetW: null);
    });
    _emitSignal(const BodyweightGoalCleared(), emit);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
