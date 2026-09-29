// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';

/// Events for [RoutineEditBloc].
/// Mirrors mutation closures in `../openGym/frontend/src/views/RoutineEdit.jsx`.
sealed class RoutineEditEvent {
  const RoutineEditEvent();
}

/// Internal notification of [GymState] changes from [GymStateCubit].
final class RoutineEditGymStateChanged extends RoutineEditEvent {
  const RoutineEditGymStateChanged(this.state);
  final GymState state;
}

/// Renames the routine; empty input falls back to localized 'Routine'.
final class RoutineRenamed extends RoutineEditEvent {
  const RoutineRenamed(this.name);
  final String name;
}

/// Updates the routine's glyph/emoji identifier.
final class RoutineGlyphChanged extends RoutineEditEvent {
  const RoutineGlyphChanged(this.glyph);
  final String glyph;
}

/// Sets the routine's default progression policy ('linear', 'double', etc.).
final class RoutineProgressionPolicyChanged extends RoutineEditEvent {
  const RoutineProgressionPolicyChanged(this.policy);
  final String policy;
}

/// Toggles routine-level exclusion from automatic progression.
final class RoutineExcludeChanged extends RoutineEditEvent {
  const RoutineExcludeChanged(this.v);
  final bool v;
}

/// Appends an exercise configuration to the routine.
final class RoutineExerciseAdded extends RoutineEditEvent {
  const RoutineExerciseAdded({
    required this.exId,
    required this.cfg,
    this.quick = false,
  });
  final String exId;
  final RoutineExercise cfg;
  final bool quick;
}

/// Updates configuration for exercise row [i] keeping id and superset group.
final class RoutineExerciseConfigured extends RoutineEditEvent {
  const RoutineExerciseConfigured(this.i, this.cfg);
  final int i;
  final RoutineExercise cfg;
}

/// Removes exercise row [i] and cleans up superset links.
final class RoutineExerciseRemoved extends RoutineEditEvent {
  const RoutineExerciseRemoved(this.i);
  final int i;
}

/// Moves a superset unit up (dir = -1) or down (dir = 1).
final class RoutineUnitMoved extends RoutineEditEvent {
  const RoutineUnitMoved(this.i, this.dir);
  final int i;
  final int dir;
}

/// Drag-and-drop reorders a superset unit from [sourceUnit] to [targetUnit].
final class RoutineUnitReordered extends RoutineEditEvent {
  const RoutineUnitReordered(this.sourceUnit, this.targetUnit);
  final int sourceUnit;
  final int targetUnit;
}

/// Toggles superset link between row [i] and [i - 1].
final class RoutineLinkToggled extends RoutineEditEvent {
  const RoutineLinkToggled(this.i);
  final int i;
}

/// Deep copies the routine with a '(Copy)' suffix and opens it.
final class RoutineCopied extends RoutineEditEvent {
  const RoutineCopied();
}

/// Deletes the routine, cleans references in week schedule and dayPlan, and returns to Plan.
final class RoutineDeleted extends RoutineEditEvent {
  const RoutineDeleted();
}
