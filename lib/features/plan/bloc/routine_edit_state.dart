// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/models/routine.dart';
import '../../../core/models/state_parts.dart';

/// One-shot signals dispatched by [RoutineEditBloc] to the UI.
sealed class RoutineEditSignal {
  const RoutineEditSignal();
}

/// Navigation signal for routine copying or deletion.
final class RoutineEditNavigateSignal extends RoutineEditSignal {
  const RoutineEditNavigateSignal(this.path);
  final String path;
}

/// Feedback toast signal.
final class RoutineEditToastSignal extends RoutineEditSignal {
  const RoutineEditToastSignal(this.message);
  final String message;
}

/// States for [RoutineEditBloc].
sealed class RoutineEditState extends Equatable {
  const RoutineEditState();

  @override
  List<Object?> get props => <Object?>[];
}

/// The requested routine does not exist in state; signals immediate navigation back to /plan.
final class RoutineEditMissing extends RoutineEditState {
  const RoutineEditMissing();
}

/// Fully resolved state for the RoutineEdit screen.
final class RoutineEditReady extends RoutineEditState {
  const RoutineEditReady({
    required this.routine,
    required this.units,
    required this.unitIndex,
    required this.unitFirst,
    required this.inSuperset,
    required this.profile,
    required this.missingCount,
    required this.noEquip,
    required this.lines,
    this.signal,
    this.seq = 0,
  });

  final Routine routine;
  final List<List<int>> units;
  final Map<int, int> unitIndex;
  final Set<int> unitFirst;
  final Set<int> inSuperset;
  final EquipProfile? profile;
  final int missingCount;
  final List<bool> noEquip;
  final List<String> lines;
  final RoutineEditSignal? signal;
  final int seq;

  RoutineEditReady withSignal(RoutineEditSignal sig) => RoutineEditReady(
        routine: routine,
        units: units,
        unitIndex: unitIndex,
        unitFirst: unitFirst,
        inSuperset: inSuperset,
        profile: profile,
        missingCount: missingCount,
        noEquip: noEquip,
        lines: lines,
        signal: sig,
        seq: seq + 1,
      );

  RoutineEditReady copyWith({
    Routine? routine,
    List<List<int>>? units,
    Map<int, int>? unitIndex,
    Set<int>? unitFirst,
    Set<int>? inSuperset,
    EquipProfile? profile,
    int? missingCount,
    List<bool>? noEquip,
    List<String>? lines,
    RoutineEditSignal? signal,
    int? seq,
  }) =>
      RoutineEditReady(
        routine: routine ?? this.routine,
        units: units ?? this.units,
        unitIndex: unitIndex ?? this.unitIndex,
        unitFirst: unitFirst ?? this.unitFirst,
        inSuperset: inSuperset ?? this.inSuperset,
        profile: profile ?? this.profile,
        missingCount: missingCount ?? this.missingCount,
        noEquip: noEquip ?? this.noEquip,
        lines: lines ?? this.lines,
        signal: signal,
        seq: seq ?? this.seq,
      );

  @override
  List<Object?> get props => <Object?>[
        routine,
        units,
        unitIndex,
        unitFirst,
        inSuperset,
        profile,
        missingCount,
        noEquip,
        lines,
        signal,
        seq,
      ];
}
