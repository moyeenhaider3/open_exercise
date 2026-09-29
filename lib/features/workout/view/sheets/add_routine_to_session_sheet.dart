// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Opens the add-routine-to-session sheet.
///
/// Already-in-session rows show 'already added' and are disabled.
/// Empty-exercise rows show 'no exercises' and are disabled.
/// Ports `../openGym/frontend/src/sheets.jsx` AddRoutineToSession lines 1913-1951.
Future<void> showAddRoutineToSessionSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _AddRoutineToSessionSheet(),
  );
}

class _AddRoutineToSessionSheet extends StatelessWidget {
  const _AddRoutineToSessionSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (BuildContext ctx, WorkoutState state) {
        if (state is! WorkoutRunning) {
          return Center(child: Text(t('No active workout.')));
        }
        final active = state.active;
        final List<String> inSession = (active.routineIds ?? <Object?>[])
            .whereType<String>()
            .toList();
        final Set<String> inSessionSet = inSession.toSet();
        final List<Routine> routines =
            context.read<GymStateCubit>().state.routines ?? const <Routine>[];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('Add routine'),
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12.0),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routines.length,
              itemBuilder: (BuildContext context, int index) {
                final Routine r = routines[index];
                final bool already = inSessionSet.contains(r.id ?? '');
                final bool empty = (r.ex ?? <RoutineExercise>[]).isEmpty;
                final bool disabled = already || empty;
                return ListItem(
                  leading: AppIcon(glyphOf(r.emoji), size: 20.0),
                  title: Text(r.name ?? ''),
                  subtitle: Text(exCount(r.ex?.length ?? 0)),
                  trailing: already
                      ? AppTag(label: t('already added'))
                      : empty
                          ? AppTag(label: t('no exercises'))
                          : const AppIcon('chevronRight', size: 16.0),
                  disabled: disabled,
                  onTap: disabled
                      ? null
                      : () {
                          ctx.read<WorkoutBloc>().add(
                                WorkoutRoutineAddedToSession(r.id ?? ''),
                              );
                          Navigator.of(ctx).pop();
                        },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
