// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Sealed base class for all states emitted by [HistoryBloc].
sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial and idle state for [HistoryBloc].
final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}
