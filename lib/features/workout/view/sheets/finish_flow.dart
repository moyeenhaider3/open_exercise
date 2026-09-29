// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase3_models.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';

/// Runs the finish-workout confirmation flow.
///
/// Ported from `../openGym/frontend/src/sheets.jsx` lines 2179-2192:
/// - If [done] == 0: asks 'Nothing logged yet' / 'Finish anyway' (danger).
/// - If [done] < [total]: asks 'Finish early?' with unchecked count / 'Finish workout'.
/// - Otherwise: completes directly by dispatching [WorkoutFinishConfirmed].
Future<void> runFinishFlow(
  BuildContext context, {
  required int done,
  required int total,
}) async {
  if (done == 0) {
    final bool confirmed = await showConfirmSheet(
      context,
      title: t('Nothing logged yet'),
      message: t('You haven’t checked off any sets. Finish the workout anyway?'),
      confirmText: t('Finish anyway'),
      danger: true,
    );
    if (confirmed && context.mounted) {
      context.read<WorkoutBloc>().add(const WorkoutFinishConfirmed());
    }
    return;
  }

  if (done < total) {
    final int unchecked = total - done;
    final bool confirmed = await showConfirmSheet(
      context,
      title: t('Finish early?'),
      message: unchecked == 1
          ? t('1 set still unchecked. Finish the workout now?')
          : t('{0} sets still unchecked. Finish the workout now?', <Object?>[unchecked]),
      confirmText: t('Finish workout'),
    );
    if (confirmed && context.mounted) {
      context.read<WorkoutBloc>().add(const WorkoutFinishConfirmed());
    }
    return;
  }

  context.read<WorkoutBloc>().add(const WorkoutFinishConfirmed());
}

/// Displays the center dialog when all exercises in the workout are complete.
///
/// Ported from `../openGym/frontend/src/sheets.jsx` lines 2146-2155 WorkoutComplete.
Future<void> showWorkoutCompleteSheet(BuildContext context) {
  final AppPalette palette = AppPalette.of(context);

  return showCenterDialog<void>(
    context,
    (BuildContext ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon('checkCircle', size: 44.0, color: palette.acc),
          const SizedBox(height: 8.0),
          Text(
            t("That's the whole workout!"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8.0),
          Text(
            t('Every exercise done — great work. Finish up, or keep going and add another exercise.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: palette.muted),
          ),
          const SizedBox(height: 20.0),
          AppButton(
            label: Text(t('Finish workout')),
            variant: AppButtonVariant.primary,
            icon: 'flag',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<WorkoutBloc>().add(const WorkoutFinishRequested());
            },
          ),
          const SizedBox(height: 8.0),
          AppButton(
            label: Text(t('Continue workout')),
            variant: AppButtonVariant.ghost,
            onPressed: () {
              Navigator.of(ctx).pop();
              showToast(context, t('Keep going — tap “+ Add exercise” below'));
            },
          ),
        ],
      );
    },
  );
}

/// Displays the locked workout summary center dialog upon completing a workout.
///
/// Ported from `../openGym/frontend/src/sheets.jsx` lines 2157-2178 FinishSummary.
/// Note: Body visualization is deferred to Phase 4; audio cues to Phase 5 (D-02).
Future<void> showFinishSummary(
  BuildContext context,
  FinishResult r,
  String unit,
) {
  final HistoryJs history = context.read<JsEngineService>().history;
  final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
  final GymStateCubit cubit = context.read<GymStateCubit>();

  return showCenterDialog<void>(
    context,
    locked: true,
    (BuildContext ctx) {
      return _FinishSummaryContent(
        result: r,
        unit: unit,
        history: history,
        catalogue: catalogue,
        gymState: cubit.state,
      );
    },
  );
}

class _FinishSummaryContent extends StatelessWidget {
  const _FinishSummaryContent({
    required this.result,
    required this.unit,
    required this.history,
    required this.catalogue,
    required this.gymState,
  });

  final FinishResult result;
  final String unit;
  final HistoryJs history;
  final ExerciseCatalogue catalogue;
  final GymState gymState;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Workout w = result.workout;
    final int durMs = ((w.end ?? 0) - (w.start ?? 0)).toInt();
    final String durText = fmtDur(durMs > 0 ? durMs : 0);
    final String volText = fmtVol(w.vol ?? 0, unit);
    final String setsText = t(
      '{0} sets · {1} work',
      <Object?>[history.setsDone(w), history.workSetsDone(w)],
    );
    final String prsCountText = result.prs.isNotEmpty ? '${result.prs.length}' : '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: AppIcon('trophy', size: 44.0, color: palette.acc),
        ),
        const SizedBox(height: 8.0),
        Text(
          t('Workout complete!'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(label: t('Duration'), value: durText),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _SummaryTile(label: t('Volume'), value: volText),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(label: t('Sets'), value: setsText),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _SummaryTile(label: t('PRs'), value: prsCountText),
            ),
          ],
        ),
        if (result.prs.isNotEmpty || result.e1prs.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14.0),
          ...result.prs.map((String id) {
            final ex = catalogue.lookup(gymState, id);
            final String exName = catalogue.exerciseNameFor(ex);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: <Widget>[
                  AppIcon('trophy', size: 14.0, color: palette.acc),
                  const SizedBox(width: 6.0),
                  Text(
                    '${t('New PR:')} ',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: palette.acc,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _capitalize(exName),
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: palette.acc,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          ...result.e1prs.map((E1rmRecordSummary p) {
            final ex = catalogue.lookup(gymState, p.id);
            final String exName = catalogue.exerciseNameFor(ex);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: <Widget>[
                  AppIcon('chartLine', size: 14.0, color: palette.acc),
                  const SizedBox(width: 6.0),
                  Text(
                    '${t('Best estimated 1RM:')} ',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: palette.acc,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_capitalize(exName)} · ${fmtNum(p.est)} $unit',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: palette.acc,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20.0),
        AppButton(
          label: Text(t('Nice!')),
          variant: AppButtonVariant.primary,
          onPressed: () {
            Navigator.of(context).pop();
            context.go(AppRoutes.home);
          },
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              color: palette.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
