// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../plan/bloc/plan_bloc.dart';
import '../../../plan/bloc/plan_event.dart';
import '../../../plan/bloc/plan_state.dart';

/// Opens the DayAddRoutine bottom sheet for a populated weekday.
///
/// Appends an additional routine to a day that already has one.
/// Mirrors `../openGym/frontend/src/sheets.jsx` DayAddRoutine lines 1644-1663.
Future<void> showDayAddRoutineSheet(BuildContext context, int day) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _DayAddRoutineSheet(day: day),
  );
}

class _DayAddRoutineSheet extends StatelessWidget {
  const _DayAddRoutineSheet({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanBloc, PlanState>(
      builder: (BuildContext ctx, PlanState state) {
        // Build the set of already-assigned routine ids for this day.
        final Set<String> on = (state.dayRoutines[day] ?? <Routine>[])
            .map((Routine r) => r.id ?? '')
            .toSet();
        final List<Routine> routines = state.routines;

        void add(String routineId) {
          ctx.read<PlanBloc>().add(PlanDayRoutineAdded(day, routineId));
          Navigator.of(ctx).pop();
        }

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
                final bool already = on.contains(r.id ?? '');
                return ListItem(
                  leading: AppIcon(glyphOf(r.emoji), size: 20.0),
                  title: Text(r.name ?? ''),
                  subtitle: Text(exCount(r.ex?.length ?? 0)),
                  trailing: already
                      ? AppTag(label: t('already added'))
                      : const AppIcon('chevronRight', size: 16.0),
                  disabled: already,
                  onTap: already ? null : () => add(r.id ?? ''),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
