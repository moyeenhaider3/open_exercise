// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/toast.dart';
import 'weight_input.dart';

/// Result type for showWeighInSheet — avoids nullable ambiguity.
/// Matches openGym BwSheet's four outcomes.
sealed class WeighInResult {
  const WeighInResult();
}

/// User saved a body weight and wants to start.
final class WeighInSaved extends WeighInResult {
  const WeighInSaved(this.bw);
  final num bw;
}

/// User chose to start without weighing in.
final class WeighInSkipped extends WeighInResult {
  const WeighInSkipped();
}

/// User cancelled (tapped ✕ / back).
final class WeighInCancelled extends WeighInResult {
  const WeighInCancelled();
}

/// User wants to choose a different workout.
final class WeighInChooseDifferent extends WeighInResult {
  const WeighInChooseDifferent();
}

/// Opens the Quick check-in weigh-in sheet (locked, required = true variant).
///
/// Ports `../openGym/frontend/src/sheets.jsx` BwSheet lines 200-252.
/// The non-required "Log body weight" variant is Phase 3.1 (Home screen).
Future<WeighInResult> showWeighInSheet(BuildContext context) async {
  final WeighInResult? result = await showAppSheet<WeighInResult>(
    context,
    (BuildContext ctx) => const _WeighInSheet(),
    locked: true,
  );
  return result ?? const WeighInCancelled();
}

class _WeighInSheet extends StatefulWidget {
  const _WeighInSheet();

  @override
  State<_WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends State<_WeighInSheet> {
  late num _value;
  late String _unit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unit = context.read<GymStateCubit>().state.unit ?? 'kg';
    final lastBw =
        context.read<JsEngineService>().history.lastBW(context.read<GymStateCubit>().state);
    _value = lastBw?.w ?? 70;
  }

  void _save() {
    final num n = ((_value * 10).round()) / 10;
    if (n <= 0) {
      showToast(context, t('Enter a valid weight'));
      return;
    }
    Navigator.of(context).pop(WeighInSaved(n));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header with cancel ✕ (closes as cancelled — no-op).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              t('Quick check-in'),
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            IconButton(
              icon: const AppIcon('xmark', size: 18.0),
              tooltip: t('Cancel'),
              onPressed: () =>
                  Navigator.of(context).pop(const WeighInCancelled()),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          t(
            'Slide or tap to set your weight — tracked before every workout so your curve stays honest.',
          ),
          style: TextStyle(
            fontSize: 13.0,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16.0),
        WeightInput(
          value: _value,
          unit: _unit,
          onChanged: (num v) => setState(() => _value = v),
        ),
        const SizedBox(height: 14.0),
        AppButton(
          label: Text(t('Save & start workout')),
          variant: AppButtonVariant.primary,
          onPressed: _save,
        ),
        const SizedBox(height: 8.0),
        AppButton(
          label: Text(t('Start without weighing in')),
          variant: AppButtonVariant.ghost,
          onPressed: () =>
              Navigator.of(context).pop(const WeighInSkipped()),
        ),
        const SizedBox(height: 2.0),
        AppButton(
          label: Text(t('Choose a different workout')),
          icon: 'reset',
          variant: AppButtonVariant.ghost,
          onPressed: () {
            Navigator.of(context).pop(const WeighInChooseDifferent());
            context.go(AppRoutes.workout);
          },
        ),
      ],
    );
  }
}
