// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// One-shot signals emitted by [BodyweightBloc].
sealed class BodyweightSignal extends Equatable {
  const BodyweightSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Emitted when weight value was invalid (<= 0).
final class BodyweightInvalid extends BodyweightSignal {
  const BodyweightInvalid();
}

/// Emitted when a bodyweight entry has been saved.
final class BodyweightSaved extends BodyweightSignal {
  const BodyweightSaved(this.value);

  final num value;

  @override
  List<Object?> get props => <Object?>[value];
}

/// Emitted when a target weight goal has been saved.
final class BodyweightGoalSaved extends BodyweightSignal {
  const BodyweightGoalSaved(this.value);

  final num value;

  @override
  List<Object?> get props => <Object?>[value];
}

/// Emitted when a target weight goal has been cleared.
final class BodyweightGoalCleared extends BodyweightSignal {
  const BodyweightGoalCleared();
}

/// State emitted by [BodyweightBloc].
final class BodyweightState extends Equatable {
  const BodyweightState({
    this.signal,
    this.seq = 0,
  });

  final BodyweightSignal? signal;
  final int seq;

  BodyweightState withSignal(BodyweightSignal sig) => BodyweightState(
        signal: sig,
        seq: seq + 1,
      );

  @override
  List<Object?> get props => <Object?>[signal, seq];
}
