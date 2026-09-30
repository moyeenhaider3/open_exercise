// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/session_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/model_extras.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../bloc/plan_bloc.dart';
import '../../bloc/plan_event.dart';

/// Opens the DayOverride bottom sheet for an ISO date string (YYYY-MM-DD).
///
/// Ported 1:1 from `../openGym/frontend/src/sheets.jsx` DayOverride lines 1593-1620.
Future<void> showDayOverrideSheet(BuildContext context, String iso) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _DayOverrideSheet(iso: iso),
  );
}

class _DayOverrideSheet extends StatelessWidget {
  const _DayOverrideSheet({required this.iso});

  final String iso;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();

    final int wd = DateTime.parse('${iso}T12:00:00').weekday % 7;
    final List<String> weeklyIds = gymState.weekRoutineIds(wd);
    final List<Routine> routines = gymState.routines ?? const <Routine>[];
    final List<String> weeklyNames = weeklyIds
        .map((String id) => routines.firstWhereOrNull((Routine r) => r.id == id)?.name)
        .nonNulls
        .toList();
    final bool hasOvr = gymState.dayPlan?.containsKey(iso) ?? false;
    final List<String> effIds = engine.history.effectiveRoutineIds(gymState, iso);

    final String sessionName = weeklyNames.isNotEmpty
        ? (engine.sessionMerge.deriveSessionName(weeklyNames) ?? t('Rest'))
        : t('Rest');

    void set(String v) {
      context.read<PlanBloc>().add(PlanDayOverrideSet(iso, v));
      Navigator.of(context).pop();
      final String toastMsg = v.isEmpty
          ? t('Back to weekly plan')
          : v == 'rest'
              ? t('{0} set to rest', <Object>[fmtDate(iso)])
              : t('{0} planned for {1}', <Object>[
                  routines.firstWhereOrNull((Routine r) => r.id == v)?.name ?? '',
                  fmtDate(iso),
                ]);
      showToast(context, toastMsg);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          fmtDate(iso, long: true),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4.0),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 13.0, color: palette.muted),
            children: <InlineSpan>[
              TextSpan(text: '${t('Weekly plan:')} $sessionName'),
              if (hasOvr)
                TextSpan(
                  text: ' · ${t('changed for this day')}',
                  style: TextStyle(color: palette.orange),
                ),
              const TextSpan(text: '\n'),
              TextSpan(
                text: t('Sick, missed a day or want a different session? Pick what to train instead.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        ...routines.map((Routine r) {
          final String rId = r.id ?? '';
          final bool checked = effIds.contains(rId);
          return ListItem(
            leading: Container(
              width: 34.0,
              height: 34.0,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(8.0),
              ),
              alignment: Alignment.center,
              child: AppIcon(glyphOf(r.emoji), size: 19.0),
            ),
            title: Text(r.name ?? ''),
            subtitle: Text(exCount(r.ex?.length ?? 0)),
            trailing: checked
                ? AppIcon('check', size: 18.0, color: palette.acc)
                : null,
            onTap: () => set(rId),
          );
        }),
        ListItem(
          leading: Container(
            width: 34.0,
            height: 34.0,
            decoration: BoxDecoration(
              color: palette.surface3,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: const AppIcon('moon', size: 19.0),
          ),
          title: Text(t('Rest / skip this day')),
          trailing: effIds.isEmpty
              ? AppIcon('check', size: 18.0, color: palette.acc)
              : null,
          onTap: () => set('rest'),
        ),
        if (hasOvr)
          ListItem(
            leading: Container(
              width: 34.0,
              height: 34.0,
              decoration: BoxDecoration(
                color: palette.surface3,
                borderRadius: BorderRadius.circular(8.0),
              ),
              alignment: Alignment.center,
              child: const AppIcon('reset', size: 19.0),
            ),
            title: Text(t('Back to weekly plan')),
            onTap: () => set(''),
          ),
      ],
    );
  }
}
