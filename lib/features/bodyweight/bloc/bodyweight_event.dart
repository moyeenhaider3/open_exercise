// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Sealed base class for all events handled by [BodyweightBloc].
sealed class BodyweightEvent extends Equatable {
  const BodyweightEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Internal event fired when [GymStateCubit] emits a new state.
final class BodyweightGymStateChanged extends BodyweightEvent {
  const BodyweightGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Dispatched to log a bodyweight reading.
/// Ported from `../openGym/frontend/src/sheets.jsx` BwSheet.save (lines 203-213).
final class BodyweightLogged extends BodyweightEvent {
  const BodyweightLogged(this.value);

  final num value;

  @override
  List<Object?> get props => <Object?>[value];
}

/// Dispatched to delete a bodyweight entry for a given date.
/// Ported from `../openGym/frontend/src/sheets.jsx` delEntry (line 217).
final class BodyweightEntryDeleted extends BodyweightEvent {
  const BodyweightEntryDeleted(this.d);

  final String d;

  @override
  List<Object?> get props => <Object?>[d];
}

/// Dispatched to set the target weight goal.
/// Ported from `../openGym/frontend/src/sheets.jsx` GoalSheet (lines 563-568).
final class BodyweightGoalSet extends BodyweightEvent {
  const BodyweightGoalSet(this.value);

  final num value;

  @override
  List<Object?> get props => <Object?>[value];
}

/// Dispatched to remove the target weight goal.
/// Ported from `../openGym/frontend/src/sheets.jsx` GoalSheet (line 571).
final class BodyweightGoalRemoved extends BodyweightEvent {
  const BodyweightGoalRemoved();
}
