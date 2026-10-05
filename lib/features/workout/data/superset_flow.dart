// SPDX-License-Identifier: AGPL-3.0-or-later
// The rest decisions (restAfterSet, restOnRecheck, restSecFor, warmupRestSecFor)
// run in openGym's JS via SupersetFlowJs (Phase 5, 05-02); this file keeps only
// the Phase 3 navigation helpers.

import '../../../core/models/workout.dart';

/// Navigation step decision in an active superset group.
final class SupersetFlowStep {
  const SupersetFlowStep({
    required this.unitDone,
    required this.roundDone,
    this.nextIdx,
  });

  final bool unitDone;
  final bool roundDone;
  final int? nextIdx;
}

bool _hasWork(List<WorkoutEntry> entries, int idx) {
  if (idx < 0 || idx >= entries.length) return false;
  final sets = entries[idx].sets;
  if (sets == null || sets.isEmpty) return false;
  return sets.any((s) => s.done != true);
}

/// Return the first unfinished navigation unit after the current one, wrapping once.
/// Ported from ../openGym/frontend/src/lib/supersetFlow.js:nextUnfinishedUnit — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
List<int>? nextUnfinishedUnit(List<WorkoutEntry> entries, List<List<int>> units, int fromIdx) {
  if (entries.isEmpty || units.isEmpty) return null;
  final int current = units.indexWhere((List<int> unit) => unit.contains(fromIdx));
  final List<List<int>> ordered = current < 0
      ? units
      : <List<int>>[
          ...units.sublist(current + 1),
          ...units.sublist(0, current),
        ];
  for (final List<int> unit in ordered) {
    if (unit.any((int idx) => _hasWork(entries, idx))) {
      return unit;
    }
  }
  return null;
}

/// Insert after the current complete navigation unit; falls back safely to end of list.
/// Ported from ../openGym/frontend/src/lib/supersetFlow.js:insertionIndexAfterCurrentUnit — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
int insertionIndexAfterCurrentUnit(List<List<int>> units, int currentIndex, int entryCount) {
  final int length = entryCount > 0 ? entryCount : 0;
  if (units.isEmpty) return length;
  List<int>? unit;
  for (final List<int> candidate in units) {
    if (candidate.contains(currentIndex)) {
      unit = candidate;
      break;
    }
  }
  if (unit == null || unit.isEmpty) return length;
  int maxIndex = unit.first;
  for (final int idx in unit) {
    if (idx > maxIndex) maxIndex = idx;
  }
  final int target = maxIndex + 1;
  return target < length ? target : length;
}

// ignore: unused_element
const String _kDocSignature = '''
({int highWater setProgressHighWater(
''';

/// Track whether completing a set is new progress for this exercise in this session.
/// Ported from ../openGym/frontend/src/lib/supersetFlow.js:setProgressHighWater — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
({int highWater, bool isNew}) setProgressHighWater(WorkoutEntry entry, [int previous = 0]) {
  final sets = entry.sets;
  int done = 0;
  if (sets != null) {
    for (final s in sets) {
      if (s.done == true) done++;
    }
  }
  return (
    isNew: done > previous,
    highWater: done > previous ? done : previous,
  );
}

/// Decide where a newly completed superset set goes next.
/// Ported from ../openGym/frontend/src/lib/supersetFlow.js:supersetFlowStep — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
SupersetFlowStep? supersetFlowStep(List<WorkoutEntry> entries, List<int> unit, int fromIdx) {
  if (entries.isEmpty || unit.length <= 1) return null;
  final int pos = unit.indexOf(fromIdx);
  if (pos < 0) return null;

  final bool unitDone = !unit.any((int idx) => _hasWork(entries, idx));
  if (unitDone) {
    return const SupersetFlowStep(unitDone: true, roundDone: false, nextIdx: null);
  }

  final List<int> wrapped = <int>[
    ...unit.sublist(pos + 1),
    ...unit.sublist(0, pos + 1),
  ];
  int? nextIdx;
  for (final int idx in wrapped) {
    if (_hasWork(entries, idx)) {
      nextIdx = idx;
      break;
    }
  }

  final List<int> laterInUnit = unit.sublist(pos + 1);
  final bool roundDone = !laterInUnit.any((int idx) => _hasWork(entries, idx));

  return SupersetFlowStep(
    unitDone: false,
    roundDone: roundDone,
    nextIdx: nextIdx,
  );
}
