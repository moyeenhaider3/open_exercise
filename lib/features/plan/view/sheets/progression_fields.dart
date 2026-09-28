// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/progression_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/model_extras.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';

/// Progression step increment for an exercise configuration.
/// Ported from ../openGym/frontend/src/sheets.jsx:1122 progressionStepOf.
num progressionStepOf(
  RoutineExercise cfg,
  ExerciseDef ex,
  String unit,
  JsEngineService engine,
) {
  if (cfg.inc != null) return cfg.inc!;
  final String mode = engine.history.modeOf(cfg);
  if (mode == 'time') {
    return engine.progression.defaultSecIncrement;
  }
  return engine.progression.defaultIncrement(ex.id, unit);
}

/// Whether the progression step increment is valid for the current policy.
/// Ported from ../openGym/frontend/src/sheets.jsx:1124 progressionStepIsValid.
// Input validation, not domain math.
bool progressionStepIsValid(String policy, num? step) {
  return policy == 'off' || (step != null && step.isFinite && step > 0);
}

/// Progression policy, increment, and deload settings sub-form.
/// Ported from ../openGym/frontend/src/sheets.jsx:1126-1175 ProgressionFields.
class ProgressionFields extends StatelessWidget {
  const ProgressionFields({
    super.key,
    required this.cfg,
    required this.ex,
    this.routine,
    required this.onChanged,
  });

  final RoutineExercise cfg;
  final ExerciseDef ex;
  final Routine? routine;
  final ValueChanged<RoutineExercise> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final GymState s = context.watch<GymStateCubit>().state;
    final String unit = s.unit ?? 'kg';

    final String mode = engine.history.modeOf(cfg);
    final String policy = engine.progression.policyFor(cfg, routine, mode);
    final List<String> availablePolicies =
        engine.progression.policiesFor[mode] ?? <String>['off'];
    final Map<String, String> policyName = engine.progression.policyName;
    final Map<String, String> policyDesc = engine.progression.policyDesc;

    final num step = progressionStepOf(cfg, ex, unit, engine);
    final bool stepValid = progressionStepIsValid(policy, step);
    final String stepUnit = mode == 'time' ? 'sec' : unit;

    // Build options for SelectRow
    final List<SelectOption<String?>> options = <SelectOption<String?>>[];
    if (routine != null) {
      final String routinePolicy =
          routine!.prog != null ? (policyName[routine!.prog] ?? routine!.prog!) : 'Linear';
      options.add(
        SelectOption<String?>(
          value: null,
          label: t('Follow the routine ({0})', <Object?>[routinePolicy]),
        ),
      );
    }
    for (final String p in availablePolicies) {
      options.add(
        SelectOption<String?>(
          value: p,
          label: policyName[p] ?? p,
          subtitle: policyDesc[p],
        ),
      );
    }

    final double deloadMin = engine.progression.deloadFactorMin;
    final double deloadMax = engine.progression.deloadFactorMax;
    final double curDeload = engine.progression.deloadFactorOf(cfg);
    final int deloadPercent = (curDeload * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SectionHeader('Progression'),
        SelectRow<String?>(
          title: t('Policy'),
          value: cfg.prog,
          options: options,
          onChanged: (String? val) {
            if (val == null) {
              onChanged(cfg.withExtraFields(
                const <String, Object?>{},
                remove: const <String>['prog'],
              ));
            } else {
              onChanged(cfg.withExtraFields(<String, Object?>{'prog': val}));
            }
          },
        ),
        if (policy != 'off') ...<Widget>[
          if (policyDesc[policy] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14.0, 4.0, 14.0, 10.0),
              child: Text(
                policyDesc[policy]!,
                style: TextStyle(fontSize: 13.0, color: palette.muted),
              ),
            ),
          AppStepper(
            label: t('Progression step ({0})', <Object?>[stepUnit]),
            step: mode == 'time' ? 5 : (unit == 'lb' ? 2.5 : 1),
            value: step,
            invalid: !stepValid,
            onChanged: (num? nextStep) {
              if (nextStep != null && nextStep > 0) {
                onChanged(cfg.withExtraFields(<String, Object?>{'inc': nextStep}));
              }
            },
          ),
          if (!stepValid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Text(
                t('Progression step must be greater than 0'),
                style: TextStyle(fontSize: 12.0, color: palette.red),
              ),
            ),
          const SizedBox(height: 8.0),
          AppStepper(
            label: t('Deload factor (%)'),
            step: 5,
            value: deloadPercent,
            onChanged: (num? nextPercent) {
              if (nextPercent != null) {
                final double factor =
                    (nextPercent / 100.0).clamp(deloadMin, deloadMax);
                onChanged(cfg.withExtraFields(<String, Object?>{
                  'deloadFactor': factor,
                }));
              }
            },
          ),
        ],
      ],
    );
  }
}
