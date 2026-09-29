// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Sealed base class for all Check-in screen events.
sealed class CheckInEvent extends Equatable {
  const CheckInEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Internal event fired when GymState updates.
final class CheckInGymStateChanged extends CheckInEvent {
  const CheckInGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Moves a card from one position to another.
/// Ported from `../openGym/frontend/src/views/CheckIn.jsx`:122.
final class CheckInCardMoved extends CheckInEvent {
  const CheckInCardMoved(this.from, this.to);

  final int from;
  final int to;

  @override
  List<Object?> get props => <Object?>[from, to];
}

/// Renames a card with a new label.
/// Ported from `../openGym/frontend/src/views/CheckIn.jsx`:170-176.
final class CheckInCardRenamed extends CheckInEvent {
  const CheckInCardRenamed(this.id, this.label);

  final String id;
  final String label;

  @override
  List<Object?> get props => <Object?>[id, label];
}

/// Removes a card from saved cards.
/// Ported from `../openGym/frontend/src/views/CheckIn.jsx`:112-118.
final class CheckInCardRemoved extends CheckInEvent {
  const CheckInCardRemoved(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Sets the currently focused card ID.
/// Ported from `../openGym/frontend/src/views/CheckIn.jsx`:61-64.
final class CheckInActiveCardChanged extends CheckInEvent {
  const CheckInActiveCardChanged(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}
