// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../data/gym_cards.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// App-scoped BLoC managing gym cards display and mutations.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Ports `../openGym/frontend/src/views/CheckIn.jsx`.
class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required GymStateCubit gymState,
  })  : _gymState = gymState,
        super(
          CheckInReady(
            cards: gymState.state.gymCards ?? const <GymCard>[],
            lastGymCardId: gymState.state.lastGymCardId,
          ),
        ) {
    _sub = _gymState.stream.listen((GymState s) {
      add(CheckInGymStateChanged(s));
    });

    on<CheckInEvent>(_onEvent);
  }

  final GymStateCubit _gymState;
  late final StreamSubscription<GymState> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }

  Future<void> _onEvent(CheckInEvent event, Emitter<CheckInState> emit) async {
    switch (event) {
      case CheckInGymStateChanged(:final GymState state):
        emit(
          CheckInReady(
            cards: state.gymCards ?? const <GymCard>[],
            lastGymCardId: state.lastGymCardId,
          ),
        );
      case CheckInCardMoved(:final int from, :final int to):
        await _onCardMoved(from, to);
      case CheckInCardRenamed(:final String id, :final String label):
        await _onCardRenamed(id, label);
      case CheckInCardRemoved(:final String id):
        await _onCardRemoved(id);
      case CheckInActiveCardChanged(:final String id):
        await _onActiveCardChanged(id);
    }
  }

  Future<void> _onCardMoved(int from, int to) async {
    await _gymState.mutate((GymState s) {
      final List<GymCard> current = s.gymCards ?? const <GymCard>[];
      final List<GymCard> next = moveGymCard(current, from, to);
      return s.copyWith(gymCards: next);
    });
  }

  Future<void> _onCardRenamed(String id, String label) async {
    final String clean = label.trim();
    final String finalLabel = clean.isNotEmpty ? clean : t('Gym card');
    await _gymState.mutate((GymState s) {
      final List<GymCard> current = s.gymCards ?? const <GymCard>[];
      final List<GymCard> next = current.map((GymCard c) {
        if (c.id == id) {
          return c.copyWith(label: finalLabel);
        }
        return c;
      }).toList();
      return s.copyWith(gymCards: next);
    });
  }

  Future<void> _onCardRemoved(String id) async {
    await _gymState.mutate((GymState s) {
      final List<GymCard> current = s.gymCards ?? const <GymCard>[];
      final List<GymCard> next = current.where((GymCard c) => c.id != id).toList();
      String? nextLastId = s.lastGymCardId;
      if (nextLastId == id) {
        nextLastId = next.isNotEmpty ? next.first.id : null;
      }
      return s.copyWith(
        gymCards: next,
        lastGymCardId: nextLastId,
      );
    });
  }

  Future<void> _onActiveCardChanged(String id) async {
    if (_gymState.state.lastGymCardId == id) return;
    await _gymState.mutate((GymState s) {
      return s.copyWith(lastGymCardId: id);
    });
  }
}
