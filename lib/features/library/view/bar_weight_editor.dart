// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/bar_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/rows.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';

/// Editor component for setting custom or default bar weight per exercise.
/// Ported from ../openGym/frontend/src/sheets.jsx:582-622 BarWeightEditor.
class BarWeightEditor extends StatelessWidget {
  const BarWeightEditor({
    super.key,
    required this.ex,
    this.extra,
  });

  final ExerciseDef ex;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BarJs bar = context.read<JsEngineService>().bar;

    return BlocBuilder<GymStateCubit, GymState>(
      builder: (BuildContext context, GymState s) {
        final String unit = s.unit ?? 'kg';
        final bool explicit = bar.hasBarOverride(s, ex.id);
        final double? def = bar.defaultBarWeight(ex.eq, unit);
        final bool noBar = bar.isNoBar(s, ex.id);
        final double? v = bar.barWeightFor(s, ex.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!noBar) ...<Widget>[
              AppStepper(
                label: t('Bar ({0})', <Object?>[unit]),
                step: 2.5,
                value: v,
                onChanged: (num? val) {
                  context.read<ExercisesBloc>().add(
                        ExerciseBarWeightChanged(ex.id, val),
                      );
                },
              ),
              const SizedBox(height: 8.0),
            ],
            AppRow(
              title: Text(t('No bar')),
              child: AppSwitch(
                value: noBar,
                onChanged: (bool on) {
                  context.read<ExercisesBloc>().add(
                        ExerciseNoBarChanged(ex.id, on),
                      );
                },
              ),
            ),
            const SizedBox(height: 4.0),
            if (noBar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Text(
                  t('Count plates only — starting at 0 {0}.', <Object?>[unit]),
                  style: TextStyle(fontSize: 13.0, color: palette.muted),
                ),
              )
            else if (!explicit)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Text(
                  t('Default for {0}: {1} {2}.', <Object?>[ex.eq, fmtNum(def ?? 0), unit]),
                  style: TextStyle(fontSize: 13.0, color: palette.muted),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () {
                    context.read<ExercisesBloc>().add(
                          ExerciseBarWeightChanged(ex.id, null),
                        );
                  },
                  child: Text(
                    t('Custom for this exercise ({0} {1} default). Tap to reset.',
                        <Object?>[fmtNum(def ?? 0), unit]),
                    style: TextStyle(fontSize: 13.0, color: palette.acc),
                  ),
                ),
              ),
            if (extra != null) ...<Widget>[
              const SizedBox(height: 8.0),
              extra!,
            ],
          ],
        );
      },
    );
  }
}

/// Opens a modal sheet for editing the bar weight of an exercise.
/// Ported from ../openGym/frontend/src/sheets.jsx:623-630 BarWeightSheet.
Future<void> showBarWeightSheet(BuildContext context, ExerciseDef ex) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t('Bar weight'),
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        BarWeightEditor(ex: ex),
      ],
    ),
  );
}
