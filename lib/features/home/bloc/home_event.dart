// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Sealed base class for all events handled by [HomeBloc].
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Dispatched when the user steps through weeks (+1 or -1).
/// Screen-local, not persisted (mirrors Home.jsx setWeekOffset).
final class HomeWeekOffsetChanged extends HomeEvent {
  const HomeWeekOffsetChanged(this.delta);

  final int delta;

  @override
  List<Object?> get props => <Object?>[delta];
}

/// Dispatched when the underlying [GymState] changes.
final class HomeGymStateChanged extends HomeEvent {
  const HomeGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}
