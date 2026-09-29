// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase3_models.dart';
import '../../../../core/js/modules/starter_js.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../plan/bloc/plan_bloc.dart';
import '../../../plan/bloc/plan_event.dart';
import '../../../plan/bloc/plan_state.dart';

/// Opens the StarterPlanChooser bottom sheet.
///
/// Lists starter plan options from StarterJs.starterPlanOptions with PLAN_COPY literals.
/// Mirrors `../openGym/frontend/src/sheets.jsx` StarterPlanChooser lines 127-159.
Future<void> showStarterPlanSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _StarterPlanSheet(),
  );
}

class _StarterPlanSheet extends StatelessWidget {
  const _StarterPlanSheet();

  @override
  Widget build(BuildContext context) {
    final List<StarterPlanOption> options =
        context.read<JsEngineService>().starter.starterPlanOptions();

    return BlocListener<PlanBloc, PlanState>(
      listenWhen: (PlanState prev, PlanState cur) =>
          cur.signal is PlanConfirmStarterSignal && cur.seq != prev.seq,
      listener: (BuildContext ctx, PlanState state) async {
        final PlanConfirmStarterSignal sig = state.signal! as PlanConfirmStarterSignal;
        final String joined = _joinDayNames(sig.dayNames);
        final bool confirmed = await showConfirmSheet(
          ctx,
          title: t('Load {0}?', <Object?>[sig.planName]),
          message: t(
            'The new plan will be scheduled on {0}. Existing routines are kept — only those days of the weekly plan change.',
            <Object?>[joined],
          ),
          confirmText: t('Load plan'),
        );
        if (confirmed && ctx.mounted) {
          ctx.read<PlanBloc>().add(PlanStarterLoaded(sig.planId));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('Choose starter plan'),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12.0),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (BuildContext ctx, int index) {
              final StarterPlanOption opt = options[index];
              final String name = _planName(opt.id);
              final String about = PlanBloc.planAbout(opt.id);
              return ListItem(
                leading: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Center(child: AppIcon('sparkles', size: 18.0)),
                ),
                title: Text(name),
                subtitle: Text(
                  t('{0} days per week', <Object?>[opt.days]) +
                      (about.isNotEmpty ? ' · $about' : ''),
                ),
                trailing: const AppIcon('chevronRight', size: 16.0),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ctx.read<PlanBloc>().add(PlanStarterLoadRequested(opt.id));
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Verbatim PLAN_COPY names from `../openGym/frontend/src/sheets.jsx` lines 103-107.
  static String _planName(String planId) {
    switch (planId) {
      case 'ppl':
        return t('Push / Pull / Legs');
      case 'upper-lower':
        return t('Upper / Lower');
      case 'full-body':
        return t('Full Body');
      case '5x5':
        return t('5×5');
      default:
        return planId;
    }
  }

  /// Joins day names in plain English, matching openGym's `dayList` (Intl.ListFormat, 'en').
  /// e.g. ['Monday', 'Wednesday', 'Friday'] → 'Monday, Wednesday, and Friday'
  static String _joinDayNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names.first} and ${names.last}';
    final List<String> parts = <String>[
      ...names.take(names.length - 1),
      'and ${names.last}',
    ];
    return parts.join(', ');
  }
}
