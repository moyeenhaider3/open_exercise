// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Shows a confirm dialog to remove an exercise from the session.
///
/// If [unit] has more than one index (superset), shows a chooser sheet first.
/// For a single-exercise unit, goes straight to the confirm.
/// Ports `../openGym/frontend/src/views/Workout.jsx` confirmRemoveExercise/removeExerciseSheet.
Future<void> showRemoveExerciseChooser(BuildContext context, List<int> unit) {
  if (unit.length > 1) {
    return showAppSheet<void>(
      context,
      (BuildContext ctx) => _RemoveExerciseChooser(unit: unit),
    );
  }
  // Single exercise: go straight to confirm.
  return confirmRemoveExercise(context, unit.first);
}

/// Shows the confirm-remove dialog for exercise at [idx].
Future<void> confirmRemoveExercise(BuildContext context, int idx) async {
  final WorkoutState st = context.read<WorkoutBloc>().state;
  if (st is! WorkoutRunning) return;
  final active = st.active;
  final entries = active.entries;
  if (entries == null || idx >= entries.length) return;
  final WorkoutEntry entry = entries[idx];
  final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
  final ex = catalogue.lookup(
    context.read<GymStateCubit>().state,
    entry.id ?? '',
  );
  final String name = catalogue.exerciseNameFor(ex);
  final bool hasDone =
      entry.sets?.any((s) => s.done == true) ?? false;

  final bool confirmed = await showConfirmSheet(
    context,
    title: t('Remove {0}?', <Object?>[_capitalize(name)]),
    message: hasDone
        ? t('The sets you logged for this exercise in this session will be lost.')
        : t('This removes the exercise from your current session.'),
    confirmText: t('Remove'),
    danger: true,
  );
  if (confirmed && context.mounted) {
    context.read<WorkoutBloc>().add(WorkoutExerciseRemoved(idx));
  }
}

class _RemoveExerciseChooser extends StatelessWidget {
  const _RemoveExerciseChooser({required this.unit});

  final List<int> unit;

  @override
  Widget build(BuildContext context) {
    final WorkoutState st = context.read<WorkoutBloc>().state;
    final List<WorkoutEntry> entries =
        (st is WorkoutRunning ? st.active.entries : null) ?? <WorkoutEntry>[];
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final gymState = context.read<GymStateCubit>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Remove exercise'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4.0),
        Text(
          t('Which exercise in this superset do you want to remove?'),
          style: TextStyle(
            fontSize: 13.0,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12.0),
        ...unit.map((int idx) {
          final WorkoutEntry? entry =
              idx < entries.length ? entries[idx] : null;
          final ex = entry != null
              ? catalogue.lookup(gymState, entry.id ?? '')
              : null;
          final String name =
              ex != null ? catalogue.exerciseNameFor(ex) : (entry?.id ?? '');
          return ListItem(
            title: Text(_capitalize(name)),
            trailing: const AppIcon('chevronRight', size: 16.0),
            onTap: () async {
              Navigator.of(context).pop();
              await confirmRemoveExercise(context, idx);
            },
          );
        }),
      ],
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
