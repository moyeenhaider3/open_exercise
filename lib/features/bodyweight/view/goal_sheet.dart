// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/phase31_models.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/view_aggregates_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/toast.dart';
import '../../workout/view/sheets/weight_input.dart';
import '../bloc/bodyweight_bloc.dart';
import '../bloc/bodyweight_event.dart';
import '../bloc/bodyweight_state.dart';

/// Opens the Target weight goal sheet.
///
/// Ports `../openGym/frontend/src/sheets.jsx` GoalSheet lines 556-575.
Future<void> showGoalSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _GoalSheet(),
  );
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet();

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late num _value;

  @override
  void initState() {
    super.initState();
    final GymState state = context.read<GymStateCubit>().state;
    final BodyweightEntry? bw = context.read<JsEngineService>().history.lastBW(state);
    _value = state.targetW ?? (bw?.w ?? 70);
  }

  void _saveGoal() {
    context.read<BodyweightBloc>().add(BodyweightGoalSet(_value));
  }

  void _removeGoal() {
    context.read<BodyweightBloc>().add(const BodyweightGoalRemoved());
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final String unit = gymState.unit ?? 'kg';

    return BlocListener<BodyweightBloc, BodyweightState>(
      listener: (BuildContext context, BodyweightState state) {
        switch (state.signal) {
          case BodyweightGoalSaved(:final num value):
            Navigator.of(context).pop();
            final GymState latestState = context.read<GymStateCubit>().state;
            final BwGoal? goal = context.read<JsEngineService>().viewAgg.bwGoal(latestState);
            final String baseMsg = t('Goal set: {0}', <Object?>['${fmtNum(value)} $unit']);
            final String toGoMsg = goal != null
                ? ' (${t('{0} to go', <Object?>[fmtNum(goal.gap)])})'
                : '';
            showToast(context, '$baseMsg$toGoMsg');
          case BodyweightGoalCleared():
            Navigator.of(context).pop();
            showToast(context, t('Goal removed'));
          case BodyweightInvalid():
            showToast(context, t('Enter a valid weight'));
          case BodyweightSaved():
          case null:
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('Target weight'),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4.0),
          Text(
            t(
              'Your goal is drawn as a line through the weight charts, and gains/losses are colored by whether they move toward it.',
            ),
            style: TextStyle(
              fontSize: 13.0,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 16.0),
          WeightInput(
            value: _value,
            unit: unit,
            onChanged: (num v) => setState(() => _value = v),
          ),
          const SizedBox(height: 14.0),
          AppButton(
            label: Text(t('Save goal')),
            variant: AppButtonVariant.primary,
            onPressed: _saveGoal,
          ),
          if (gymState.targetW != null) ...<Widget>[
            const SizedBox(height: 8.0),
            AppButton(
              label: Text(t('Remove goal')),
              variant: AppButtonVariant.danger,
              onPressed: _removeGoal,
            ),
          ],
        ],
      ),
    );
  }
}
