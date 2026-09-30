// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/gym_state.dart';

sealed class MuscleBalanceEvent extends Equatable {
  const MuscleBalanceEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class MuscleBalanceGymStateChanged extends MuscleBalanceEvent {
  const MuscleBalanceGymStateChanged(this.state);

  final GymState state;

  @override
  List<Object?> get props => <Object?>[state];
}

final class MuscleBalanceViewChanged extends MuscleBalanceEvent {
  const MuscleBalanceViewChanged(this.view);

  final String view;

  @override
  List<Object?> get props => <Object?>[view];
}

final class MuscleBalanceWindowChanged extends MuscleBalanceEvent {
  const MuscleBalanceWindowChanged(this.win);

  final int win;

  @override
  List<Object?> get props => <Object?>[win];
}

final class MuscleBalanceHardToggled extends MuscleBalanceEvent {
  const MuscleBalanceHardToggled();

  @override
  List<Object?> get props => const <Object?>[];
}

final class MuscleBalanceMuscleToggled extends MuscleBalanceEvent {
  const MuscleBalanceMuscleToggled(this.slug);

  final String slug;

  @override
  List<Object?> get props => <Object?>[slug];
}

final class MuscleBalanceTicked extends MuscleBalanceEvent {
  const MuscleBalanceTicked();

  @override
  List<Object?> get props => const <Object?>[];
}
