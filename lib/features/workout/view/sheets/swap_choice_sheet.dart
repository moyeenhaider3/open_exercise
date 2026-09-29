// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../data/active_exercise_swap.dart';

/// Shows the choice dialog/sheet when swapping an active exercise.
///
/// Ported from `sheets.jsx` lines 1043-1075:
/// - If no logged sets: returns SwapOptions() directly without prompting.
/// - If logged sets and superset: shows sheet with options:
///   "Keep replacement in this group" (groupDisposition: 'keep')
///   "Insert after this group" (groupDisposition: 'detach')
/// - If logged sets and not superset: shows confirm sheet:
///   title: 'Swap exercise?'
///   message: 'Logged sets stay with the original exercise. The replacement will be inserted afterward.'
///   confirmText: 'Continue'
Future<SwapOptions?> showSwapChoiceSheet(
  BuildContext context, {
  required WorkoutEntry current,
}) async {
  final bool hasLogged =
      current.sets != null && current.sets!.any((s) => s.done == true);

  if (!hasLogged) {
    return const SwapOptions();
  }

  if (current.sg != null) {
    return showAppSheet<SwapOptions>(
      context,
      (BuildContext ctx) => const _SupersetSwapChoiceSheet(),
    );
  }

  final bool confirmed = await showConfirmSheet(
    context,
    title: t('Swap exercise?'),
    message: t(
      'Logged sets stay with the original exercise. The replacement will be inserted afterward.',
    ),
    confirmText: t('Continue'),
  );

  if (!confirmed) return null;
  return const SwapOptions(loggedConfirmed: true);
}

class _SupersetSwapChoiceSheet extends StatelessWidget {
  const _SupersetSwapChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Swap exercise?'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6.0),
        Text(
          t(
            'Logged sets stay with the original exercise. Choose where the replacement belongs.',
          ),
          style: TextStyle(
            fontSize: 14.0,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16.0),
        AppButton(
          label: Text(t('Keep replacement in this group')),
          variant: AppButtonVariant.primary,
          onPressed: () {
            Navigator.of(context).pop(
              const SwapOptions(
                loggedConfirmed: true,
                groupDisposition: 'keep',
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
        AppButton(
          label: Text(t('Insert after this group')),
          variant: AppButtonVariant.ghost,
          onPressed: () {
            Navigator.of(context).pop(
              const SwapOptions(
                loggedConfirmed: true,
                groupDisposition: 'detach',
              ),
            );
          },
        ),
      ],
    );
  }
}
