// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/state_parts.dart';

/// Sealed base class for Check-in screen state.
sealed class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => <Object?>[];
}

/// State carrying the list of gym cards and last focused card ID.
final class CheckInReady extends CheckInState {
  const CheckInReady({
    this.cards = const <GymCard>[],
    this.lastGymCardId,
  });

  final List<GymCard> cards;
  final String? lastGymCardId;

  @override
  List<Object?> get props => <Object?>[cards, lastGymCardId];
}
