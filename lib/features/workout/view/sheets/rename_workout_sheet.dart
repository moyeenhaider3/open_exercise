// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Opens the rename workout sheet.
///
/// maxLength 60, Save disabled when empty, placeholder 'Workout title'.
/// Dispatches [WorkoutRenamed]. Closes if active disappears.
/// Ports `../openGym/frontend/src/sheets.jsx` RenameWorkout lines 2105-2140.
Future<void> showRenameWorkoutSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _RenameWorkoutSheet(),
  );
}

class _RenameWorkoutSheet extends StatefulWidget {
  const _RenameWorkoutSheet();

  @override
  State<_RenameWorkoutSheet> createState() => _RenameWorkoutSheetState();
}

class _RenameWorkoutSheetState extends State<_RenameWorkoutSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final WorkoutState st = context.read<WorkoutBloc>().state;
    final String current = st is WorkoutRunning
        ? (st.active.name ?? '')
        : '';
    _ctrl = TextEditingController(text: current);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final String trimmed = _ctrl.text.trim().substring(
          0,
          _ctrl.text.trim().length > 60 ? 60 : _ctrl.text.trim().length,
        );
    if (trimmed.isEmpty) return;
    context.read<WorkoutBloc>().add(WorkoutRenamed(trimmed));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (BuildContext ctx, WorkoutState state) {
        if (state is WorkoutNone) Navigator.of(ctx).pop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('Rename workout'),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: t('Workout title'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18.0),
          AppButton(
            label: Text(t('Save')),
            variant: AppButtonVariant.primary,
            onPressed: _ctrl.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}
