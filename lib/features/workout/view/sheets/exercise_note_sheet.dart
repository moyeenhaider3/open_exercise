// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Opens the exercise note sheet for a given workout entry index.
///
/// Closes itself when the entry disappears (mirrors openGym's useEffect guard).
/// Ports `../openGym/frontend/src/sheets.jsx` ExerciseNote lines 2019-2071.
Future<void> showExerciseNoteSheet(BuildContext context, int entryIdx) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _ExerciseNoteSheet(entryIdx: entryIdx),
  );
}

class _ExerciseNoteSheet extends StatefulWidget {
  const _ExerciseNoteSheet({required this.entryIdx});

  final int entryIdx;

  @override
  State<_ExerciseNoteSheet> createState() => _ExerciseNoteSheetState();
}

class _ExerciseNoteSheetState extends State<_ExerciseNoteSheet> {
  late TextEditingController _noteCtrl;
  late TextEditingController _standingCtrl;
  bool _pin = false;
  late int _noteMax;

  @override
  void initState() {
    super.initState();
    final JsEngineService engine = context.read<JsEngineService>();
    _noteMax = engine.history.noteMax;
    final WorkoutState st = context.read<WorkoutBloc>().state;
    WorkoutEntry? entry;
    if (st is WorkoutRunning) {
      final active = st.active;
      if (widget.entryIdx < (active.entries?.length ?? 0)) {
        entry = active.entries![widget.entryIdx];
      }
    }
    _noteCtrl =
        TextEditingController(text: entry?.extra['note'] as String? ?? '');
    _pin = entry?.extra['notePin'] == true;

    final String? standing = entry != null
        ? engine.history
            .exNoteFor(context.read<GymStateCubit>().state, entry.id ?? '')
        : null;
    _standingCtrl = TextEditingController(text: standing ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _standingCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<WorkoutBloc>().add(WorkoutExerciseNoteSaved(
          entryIdx: widget.entryIdx,
          today: _noteCtrl.text.trim(),
          pin: _pin,
          standing: _standingCtrl.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.read<ExerciseCatalogue>();
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (BuildContext ctx, WorkoutState state) {
        // Guard: close if the entry disappears (mirrors openGym's useEffect bail-out).
        if (state is WorkoutNone) {
          Navigator.of(ctx).pop();
          return;
        }
        if (state is WorkoutRunning) {
          final active = state.active;
          if (widget.entryIdx >= (active.entries?.length ?? 0)) {
            Navigator.of(ctx).pop();
          }
        }
      },
      child: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (BuildContext ctx, WorkoutState state) {
          String exName = '';
          if (state is WorkoutRunning) {
            final active = state.active;
            if (widget.entryIdx < (active.entries?.length ?? 0)) {
              final entry = active.entries![widget.entryIdx];
              final ex = catalogue.lookup(
                context.read<GymStateCubit>().state,
                entry.id ?? '',
              );
              exName = catalogue.exerciseNameFor(ex);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (exName.isNotEmpty)
                Text(
                  _capitalize(exName),
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 6.0),
              Text(
                t('This session'),
                style: TextStyle(
                  fontSize: 13.0,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: _noteMax,
                decoration: InputDecoration(
                  hintText: t(
                    'How it went, what to change — kept with today\'s workout.',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10.0),
              AppRow(
                icon: 'flag',
                iconTint: Theme.of(ctx).colorScheme.secondary,
                title: Text(t('Show this next time')),
                subtitle: Text(
                  t('Brings it up again the next time you train this exercise.'),
                ),
                value: AppSwitch(
                  value: _pin,
                  onChanged: _noteCtrl.text.trim().isEmpty
                      ? null
                      : (bool v) => setState(() => _pin = v),
                ),
              ),
              const SizedBox(height: 18.0),
              Text(
                t('Always for this exercise'),
                style: TextStyle(
                  fontSize: 13.0,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: _standingCtrl,
                maxLines: 2,
                maxLength: _noteMax,
                decoration: InputDecoration(
                  hintText: t(
                    'Seat height, pin position, a form cue — shown every session.',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18.0),
              AppButton(
                label: Text(t('Save')),
                variant: AppButtonVariant.primary,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
