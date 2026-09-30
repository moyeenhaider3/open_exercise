// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

/// Events for [StatsBloc].
sealed class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Private event dispatched when underlying [GymState] changes.
final class StatsGymStateChanged extends StatsEvent {
  const StatsGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

/// Changes bodyweight chart history window in days (default 90).
final class StatsRangeChanged extends StatsEvent {
  const StatsRangeChanged(this.days);

  final int days;

  @override
  List<Object?> get props => <Object?>[days];
}

/// Selects an exercise for the progress card.
final class StatsExerciseSelected extends StatsEvent {
  const StatsExerciseSelected(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Changes the exercise progress chart metric ('top' | 'e1rm' | 'effort').
final class StatsExerciseMetricChanged extends StatsEvent {
  const StatsExerciseMetricChanged(this.metric);

  final String metric;

  @override
  List<Object?> get props => <Object?>[metric];
}

/// Changes effort statistics rolling window in days (default 90).
final class StatsEffortWindowChanged extends StatsEvent {
  const StatsEffortWindowChanged(this.days);

  final int days;

  @override
  List<Object?> get props => <Object?>[days];
}
