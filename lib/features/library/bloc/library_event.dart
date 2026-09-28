// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Events for [LibraryBloc].
sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial event to start listening to state changes and compute initial results.
final class LibraryStarted extends LibraryEvent {
  const LibraryStarted();
}

/// Internal event dispatched when the underlying [GymState] changes.
final class LibraryGymStateChanged extends LibraryEvent {
  const LibraryGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Dispatched when the user edits the search text.
final class LibraryQueryChanged extends LibraryEvent {
  const LibraryQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Dispatched when a body part chip is selected.
/// Empty string indicates 'All' and clears the equipment filter.
final class LibraryBodyPartSelected extends LibraryEvent {
  const LibraryBodyPartSelected(this.bodyPart);

  final String bodyPart;

  @override
  List<Object?> get props => <Object?>[bodyPart];
}

/// Dispatched when an equipment chip is selected.
final class LibraryEquipmentSelected extends LibraryEvent {
  const LibraryEquipmentSelected(this.equipment);

  final String equipment;

  @override
  List<Object?> get props => <Object?>[equipment];
}

/// Dispatched when toggling between active equipment profile and showing all equipment.
final class LibraryShowAllToggled extends LibraryEvent {
  const LibraryShowAllToggled();
}

/// Dispatched when requesting to load 40 more exercises.
final class LibraryShowMoreRequested extends LibraryEvent {
  const LibraryShowMoreRequested();
}
