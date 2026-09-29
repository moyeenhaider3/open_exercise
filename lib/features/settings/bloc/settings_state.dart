// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Sealed base class for one-shot signals emitted by [SettingsBloc].
sealed class SettingsSignal extends Equatable {
  const SettingsSignal();

  @override
  List<Object?> get props => <Object?>[];
}

/// Emitted after full data reset is committed.
final class SettingsResetDone extends SettingsSignal {
  const SettingsResetDone();
}

/// State of [SettingsBloc].
class SettingsState extends Equatable {
  const SettingsState({
    this.seq = 0,
    this.signal,
  });

  final int seq;
  final SettingsSignal? signal;

  SettingsState copyWith({
    int? seq,
    SettingsSignal? signal,
  }) {
    return SettingsState(
      seq: seq ?? this.seq,
      signal: signal,
    );
  }

  @override
  List<Object?> get props => <Object?>[seq, signal];
}
