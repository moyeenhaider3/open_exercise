// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../library/bloc/exercises_bloc.dart';
import '../../../library/bloc/exercises_event.dart';
import 'ex_config_sheet.dart';

/// Opens the sheet to add an exercise to an existing routine or create a new routine.
/// Ported from ../openGym/frontend/src/sheets.jsx:755-785 AddToRoutine.
///
/// CONTRACT:
/// Toast feedback and navigation to a newly created routine are handled by a
/// `BlocListener<ExercisesBloc, ExercisesState>` mounted on calling screens
/// (e.g. ExerciseDetail, Library), not directly by this sheet. The listener reacts
/// to `ExercisesSignalAddedToRoutine` by calling `showToast` and, if requested,
/// navigating via `context.go(AppRoutes.routinePath(id))`.
Future<void> showAddToRoutineSheet(BuildContext context, ExerciseDef ex) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _AddToRoutineSheet(ex: ex),
  );
}

class _AddToRoutineSheet extends StatelessWidget {
  const _AddToRoutineSheet({required this.ex});

  final ExerciseDef ex;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState s = context.watch<GymStateCubit>().state;
    final List<Routine> routines = s.routines ?? const <Routine>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 4.0),
          child: Text(
            t('“{0}”', <Object?>[capWords(ex.n)]),
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 0.0, 14.0, 12.0),
          child: Text(
            t('Choose a routine to add this exercise to.'),
            style: TextStyle(fontSize: 14.0, color: palette.muted),
          ),
        ),
        const SizedBox(height: 8.0),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360.0),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: routines.length + 1,
            itemBuilder: (BuildContext ctx, int index) {
              if (index == routines.length) {
                // New routine action row
                return ListItem(
                  leading: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: palette.acc.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: AppIcon('plus', size: 20.0, color: palette.acc),
                    ),
                  ),
                  title: Text(
                    t('New routine'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.acc,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showExConfigSheet(
                      context,
                      ex: ex,
                      routine: null,
                      onSave: (RoutineExercise cfg) {
                        context.read<ExercisesBloc>().add(
                              ExerciseAddedToRoutine(
                                exercise: ex,
                                routineId: null,
                                config: cfg,
                              ),
                            );
                      },
                    );
                  },
                );
              }

              final Routine routine = routines[index];
              final bool alreadyIn =
                  routine.ex?.any((RoutineExercise e) => e.id == ex.id) ?? false;
              final String glyph = glyphOf(routine.emoji);
              final int count = routine.ex?.length ?? 0;

              return ListItem(
                leading: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: AppIcon(glyph, size: 20.0, color: palette.muted),
                  ),
                ),
                title: Text(routine.name ?? t('Routine')),
                subtitle: Text(t('{0} exercises', <Object?>[count])),
                trailing: alreadyIn
                    ? AppTag(label: t('In routine'))
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showExConfigSheet(
                    context,
                    ex: ex,
                    routine: routine,
                    onSave: (RoutineExercise cfg) {
                      context.read<ExercisesBloc>().add(
                            ExerciseAddedToRoutine(
                              exercise: ex,
                              routineId: routine.id,
                              config: cfg,
                            ),
                          );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
