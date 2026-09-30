// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Events for [MusclesBloc].
sealed class MusclesEvent extends Equatable {
  const MusclesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial event to start listening to state changes and compute initial results.
final class MusclesStarted extends MusclesEvent {
  const MusclesStarted();
}

/// Internal event dispatched when the underlying [GymState] changes.
final class MusclesGymStateChanged extends MusclesEvent {
  const MusclesGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Dispatched when tapping a muscle on the body map or chip.
final class MusclesMuscleTapped extends MusclesEvent {
  const MusclesMuscleTapped(this.slug);

  final String slug;

  @override
  List<Object?> get props => <Object?>[slug];
}

/// Dispatched when the user edits the search query.
final class MusclesQueryChanged extends MusclesEvent {
  const MusclesQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Dispatched when a body part filter chip is selected.
final class MusclesBodyPartSelected extends MusclesEvent {
  const MusclesBodyPartSelected(this.bodyPart);

  final String bodyPart;

  @override
  List<Object?> get props => <Object?>[bodyPart];
}

/// Dispatched when an equipment filter chip is selected.
final class MusclesEquipmentSelected extends MusclesEvent {
  const MusclesEquipmentSelected(this.equipment);

  final String equipment;

  @override
  List<Object?> get props => <Object?>[equipment];
}

/// Dispatched when toggling between active equipment profile and showing all equipment.
final class MusclesShowAllToggled extends MusclesEvent {
  const MusclesShowAllToggled();
}

/// Dispatched when requesting to load 40 more exercises.
final class MusclesShowMoreRequested extends MusclesEvent {
  const MusclesShowMoreRequested();
}
