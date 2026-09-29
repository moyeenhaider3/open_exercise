// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Opens the session note sheet.
///
/// Closes itself if the active workout disappears.
/// Ports `../openGym/frontend/src/sheets.jsx` SessionNote lines 2078-2103.
Future<void> showSessionNoteSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _SessionNoteSheet(),
  );
}

class _SessionNoteSheet extends StatefulWidget {
  const _SessionNoteSheet();

  @override
  State<_SessionNoteSheet> createState() => _SessionNoteSheetState();
}

class _SessionNoteSheetState extends State<_SessionNoteSheet> {
  late TextEditingController _ctrl;
  late int _noteMax;

  @override
  void initState() {
    super.initState();
    _noteMax = context.read<JsEngineService>().history.noteMax;
    final WorkoutState st = context.read<WorkoutBloc>().state;
    final String current = st is WorkoutRunning
        ? (st.active.extra['note'] as String? ?? '')
        : '';
    _ctrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
            t('Session note'),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            maxLength: _noteMax,
            decoration: InputDecoration(
              hintText: t('How the session went as a whole.'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18.0),
          AppButton(
            label: Text(t('Save')),
            variant: AppButtonVariant.primary,
            onPressed: () {
              context.read<WorkoutBloc>().add(
                    WorkoutSessionNoteChanged(_ctrl.text.trim()),
                  );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
