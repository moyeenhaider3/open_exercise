// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/js/modules/history_js.dart';
import '../../../core/models/workout.dart';

/// Options governing the active exercise swap behavior for logged sets.
final class SwapOptions {
  const SwapOptions({
    this.loggedConfirmed = false,
    this.groupDisposition,
  });

  /// Whether the user has explicitly confirmed swapping an exercise that has logged sets.
  final bool loggedConfirmed;

  /// Disposition for superset grouping when swapping a grouped exercise ('keep' or 'detach').
  final String? groupDisposition;
}

/// Swap one exact active-workout occurrence.
/// Ported from ../openGym/frontend/src/lib/active-exercise-swap.js:swapActiveExercise — flow control, not domain math (JS-04 N/A, 03-RESEARCH Pattern 2)
Workout? swapActiveExercise(
  Workout active,
  int index,
  WorkoutEntry replacement, {
  SwapOptions options = const SwapOptions(),
  required HistoryJs history,
}) {
  final List<WorkoutEntry>? entries = active.entries;
  if (entries == null || index < 0 || index >= entries.length) return null;

  final WorkoutEntry current = entries[index];
  final bool hasLogged =
      current.sets != null && current.sets!.any((s) => s.done == true);

  if (!hasLogged) {
    // Unlogged occurrences are replaced in place.
    final Map<String, Object?> extra = Map<String, Object?>.from(current.extra);
    extra.remove('id');
    extra.remove('target');
    extra.remove('plan');
    extra.remove('sets');
    extra.remove('sg');

    final WorkoutEntry updated = replacement.copyWith(
      sg: current.sg,
      extra: <String, Object?>{
        ...extra,
        ...replacement.extra,
      },
    );

    final List<WorkoutEntry> nextEntries = List<WorkoutEntry>.from(entries);
    nextEntries[index] = updated;

    return active.copyWith(
      entries: nextEntries,
      cur: index,
    );
  }

  if (!options.loggedConfirmed) return null;
  if (current.sg != null &&
      options.groupDisposition != 'keep' &&
      options.groupDisposition != 'detach') {
    return null;
  }

  final List<List<int>> units = history.supersetUnits(entries);
  final List<int> unit = history.unitOf(units, index);
  final bool keepGroup = current.sg != null && options.groupDisposition == 'keep';
  final int insertAt = keepGroup
      ? index + 1
      : (unit.length > 1 ? unit.last + 1 : index + 1);

  final WorkoutEntry inserted = replacement.copyWith(
    rid: current.rid,
    sg: keepGroup ? current.sg : null,
  );

  final List<WorkoutEntry> nextEntries = List<WorkoutEntry>.from(entries);
  nextEntries.insert(insertAt, inserted);

  return active.copyWith(
    entries: nextEntries,
    cur: insertAt,
  );
}
