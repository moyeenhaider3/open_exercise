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

/// Opens the DayAssign bottom sheet for a weekday.
///
/// A single-pick sheet that sets a day to one routine or clears it.
/// Mirrors `../openGym/frontend/src/sheets.jsx` DayAssign lines 1622-1640.
Future<void> showDayAssignSheet(BuildContext context, int day) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _DayAssignSheet(day: day),
  );
}

class _DayAssignSheet extends StatelessWidget {
  const _DayAssignSheet({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanBloc, PlanState>(
      builder: (BuildContext ctx, PlanState state) {
        final List<String> cur = ctx.read<PlanBloc>().state.routines.isNotEmpty
            ? (ctx
                    .read<PlanBloc>()
                    .state
                    .dayRoutines[day]
                    ?.map((Routine r) => r.id ?? '')
                    .toList() ??
                <String>[])
            : <String>[];
        final List<Routine> routines = state.routines;

        void pick(String? routineId) {
          ctx.read<PlanBloc>().add(PlanDayAssigned(day, routineId));
          Navigator.of(ctx).pop();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t(kDayNames[day]),
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12.0),
            // Rest day row
            ListItem(
              leading: AppIcon('moon', size: 20.0),
              title: Text(t('Rest day')),
              trailing: cur.isEmpty ? const AppIcon('check', size: 18.0) : null,
              onTap: () => pick(''),
            ),
            // Routine rows
            ...routines.map((Routine r) {
              final bool checked = cur.contains(r.id ?? '');
              return ListItem(
                leading: AppIcon(glyphOf(r.emoji), size: 20.0),
                title: Text(r.name ?? ''),
                subtitle: Text(exCount(r.ex?.length ?? 0)),
                trailing: checked ? const AppIcon('check', size: 18.0) : null,
                onTap: () => pick(r.id),
              );
            }),
          ],
        );
      },
    );
  }
}
