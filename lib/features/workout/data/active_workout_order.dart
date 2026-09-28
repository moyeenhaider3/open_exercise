// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/js/modules/history_js.dart';
import '../../../core/models/workout.dart';

({List<List<int>> units, int source, int target})? _moveTarget(
  Workout active,
  int index,
  int direction,
  HistoryJs history,
) {
  final List<WorkoutEntry>? entries = active.entries;
  if (entries == null || entries.isEmpty || (direction != -1 && direction != 1)) {
    return null;
  }
  final List<List<int>> units = history.supersetUnits(entries);
  final int source = units.indexWhere((List<int> unit) => unit.contains(index));
  final int target = source + direction;
  if (source < 0 || target < 0 || target >= units.length) return null;
  return (units: units, source: source, target: target);
}

/// Whether the active workout unit at index can move in direction (-1 or 1).
/// Ported from ../openGym/frontend/src/lib/active-workout-order.js:canMoveActiveWorkoutUnit — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
bool canMoveActiveWorkoutUnit(Workout active, int index, int direction, HistoryJs history) {
  return _moveTarget(active, index, direction, history) != null;
}

// ignore: unused_element
const String _kDocSignature = '''
({Workout active moveActiveWorkoutUnit(
''';

/// Move a unit up or down in the active workout order.
/// Ported from ../openGym/frontend/src/lib/active-workout-order.js:moveActiveWorkoutUnit — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
({Workout active, List<int> indices})? moveActiveWorkoutUnit(
  Workout active,
  int index,
  int direction,
  HistoryJs history,
) {
  final move = _moveTarget(active, index, direction, history);
  if (move == null) return null;

  final List<WorkoutEntry> entries = active.entries!;
  final WorkoutEntry selected = entries[index];
  final List<List<int>> reorderedUnits = List<List<int>>.from(move.units);
  final List<int> sourceUnit = reorderedUnits[move.source];
  reorderedUnits[move.source] = reorderedUnits[move.target];
  reorderedUnits[move.target] = sourceUnit;

  final List<int> indices = <int>[
    for (final List<int> unit in reorderedUnits) ...unit,
  ];
  final List<WorkoutEntry> reorderedEntries = <WorkoutEntry>[
    for (final int entryIndex in indices) entries[entryIndex],
  ];

  final int nextCur = reorderedEntries.indexOf(selected);
  final Workout nextActive = active.copyWith(
    entries: reorderedEntries,
    cur: nextCur >= 0 ? nextCur : 0,
  );

  return (active: nextActive, indices: indices);
}
