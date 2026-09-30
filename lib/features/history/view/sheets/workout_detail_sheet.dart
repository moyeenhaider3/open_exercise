// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/format/set_label.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/phase31_models.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/view_aggregates_js.dart';
import '../../../../core/js/modules/workout_model_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/model_extras.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../../library/view/exercise_media.dart';
import '../../bloc/history_bloc.dart';
import '../../bloc/history_event.dart';

/// Opens the WorkoutDetail bottom sheet for a completed [Workout].
///
/// Ported 1:1 from `../openGym/frontend/src/sheets.jsx` WorkoutDetail lines 1666-1742.
Future<void> showWorkoutDetailSheet(BuildContext context, Workout w) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _WorkoutDetailSheet(initialWorkout: w),
  );
}

class _WorkoutDetailSheet extends StatefulWidget {
  const _WorkoutDetailSheet({required this.initialWorkout});

  final Workout initialWorkout;

  @override
  State<_WorkoutDetailSheet> createState() => _WorkoutDetailSheetState();
}

class _WorkoutDetailSheetState extends State<_WorkoutDetailSheet> {
  late final TextEditingController _noteController;
  late final FocusNode _noteFocusNode;
  late final String _initialNote;
  late HistoryBloc _historyBloc;
  String _lastSavedNote = '';

  @override
  void initState() {
    super.initState();
    _initialNote = widget.initialWorkout.note ?? '';
    _lastSavedNote = _initialNote;
    _noteController = TextEditingController(text: _initialNote);
    _noteFocusNode = FocusNode();
    _noteFocusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyBloc = context.read<HistoryBloc>();
  }

  void _onFocusChange() {
    if (!_noteFocusNode.hasFocus) {
      _saveNote();
    }
  }

  void _saveNote() {
    final String current = _noteController.text;
    if (current != _lastSavedNote) {
      _lastSavedNote = current;
      _historyBloc.add(
        HistoryWorkoutNoteSaved(widget.initialWorkout.id ?? '', current),
      );
    }
  }

  @override
  void dispose() {
    _noteFocusNode.removeListener(_onFocusChange);
    _noteFocusNode.dispose();
    final String text = _noteController.text;
    if (text.trim() != _initialNote.trim()) {
      _historyBloc.add(
        HistoryWorkoutNoteSaved(widget.initialWorkout.id ?? '', text),
      );
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();

    final Workout w = (gymState.workouts ?? const <Workout>[])
            .firstWhereOrNull((Workout item) => item.id == widget.initialWorkout.id) ??
        widget.initialWorkout;

    final String unit = gymState.unit ?? 'kg';
    final List<String> headerParts = <String>[];
    if (w.d != null && w.d!.isNotEmpty) {
      headerParts.add(fmtDate(w.d!, long: true));
    }
    if (w.end != null && w.start != null) {
      final int durMs = (w.end! - w.start!).round();
      if (durMs >= 60000) {
        headerParts.addAll(durPart(durMs));
      }
    }
    headerParts.add(fmtVol(w.vol ?? 0, unit));
    if (w.bw != null) {
      headerParts.add('${fmtNum(w.bw!)} $unit');
    }

    final WorkoutDetailGroups groupsData = engine.viewAgg.workoutDetailGroups(w);
    final List<WorkoutEntry> entries = w.entries ?? const <WorkoutEntry>[];

    Widget buildEntryRow(WorkoutEntry e, int i) {
      final ExerciseDef? ex = catalogue.byId(e.id ?? '');
      final String rawName = ex != null
          ? catalogue.exerciseNameFor(ex)
          : ((e.extra['n'] as String?) ?? e.id ?? '');
      final String exName = _capitalize(rawName);

      final List<SetEntry> completedSets = (e.sets ?? const <SetEntry>[])
          .where(engine.workoutModel.hasCompletedWork)
          .toList();

      final String setsSubtitle = completedSets.isNotEmpty
          ? completedSets
              .map((SetEntry s) => setLabel(engine, e.id ?? '', s, e.target))
              .join('  ·  ')
          : t('no sets');

      final bool hasPr = w.prs != null && w.prs!.contains(e.id);
      final String? noteText = e.note;
      final bool hasNote = noteText != null && noteText.isNotEmpty;

      return Padding(
        key: ValueKey<int>(i),
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (ex != null) ...<Widget>[
              ExerciseThumb(ex: ex, size: 40.0),
              const SizedBox(width: 10.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          exName,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasPr) ...<Widget>[
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: palette.yellow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AppIcon(
                                'trophy',
                                size: 12.0,
                                color: palette.yellow,
                              ),
                              const SizedBox(width: 3.0),
                              Text(
                                'PR',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: palette.yellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    setsSubtitle,
                    style: TextStyle(
                      fontSize: 13.0,
                      color: palette.muted,
                    ),
                  ),
                  if (hasNote) ...<Widget>[
                    const SizedBox(height: 3.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        if (e.notePin) ...<Widget>[
                          AppIcon(
                            'flag',
                            size: 12.0,
                            color: palette.yellow,
                          ),
                          const SizedBox(width: 4.0),
                        ],
                        Expanded(
                          child: Text(
                            noteText,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: palette.dim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          (w.name ?? '').isNotEmpty ? w.name! : t('Workout'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4.0),
        Text(
          headerParts.join(' · '),
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 12.0),
        if (groupsData.grouped)
          ...groupsData.groups.map((WorkoutDetailGroup g) {
            final Routine? r = g.rid != null
                ? (gymState.routines ?? const <Routine>[])
                    .firstWhereOrNull((Routine x) => x.id == g.rid)
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 2.0, bottom: 8.0),
                  padding: const EdgeInsets.only(bottom: 6.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.sep)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (r != null) ...<Widget>[
                            AppIcon(glyphOf(r.emoji), size: 16.0),
                            const SizedBox(width: 7.0),
                          ],
                          Text(
                            r != null ? (r.name ?? '') : t('Freestyle'),
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${t('{0} sets', <Object>[g.setN])} · ${fmtVol(g.vol, unit)}',
                        style: TextStyle(fontSize: 13.0, color: palette.dim),
                      ),
                    ],
                  ),
                ),
                ...g.items.map((int idx) {
                  if (idx >= 0 && idx < entries.length) {
                    return buildEntryRow(entries[idx], idx);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          })
        else
          ...entries.mapIndexed((int idx, WorkoutEntry e) => buildEntryRow(e, idx)),
        const SizedBox(height: 4.0),
        Text(
          t('Session note'),
          style: TextStyle(fontSize: 13.0, color: palette.muted),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: _noteController,
          focusNode: _noteFocusNode,
          maxLines: 3,
          minLines: 2,
          maxLength: engine.history.noteMax,
          style: const TextStyle(fontSize: 14.0),
          decoration: InputDecoration(
            hintText: t('How the session went as a whole.'),
            hintStyle: TextStyle(color: palette.dim),
            filled: true,
            fillColor: palette.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12.0),
          ),
        ),
        const SizedBox(height: 14.0),
        AppButton(
          label: Text(t('Delete workout')),
          variant: AppButtonVariant.danger,
          onPressed: () async {
            final bool confirmed = await showConfirmSheet(
              context,
              title: t('Delete workout?'),
              message: t('This removes it from your history for good.'),
              confirmText: t('Delete'),
              danger: true,
            );
            if (!context.mounted) return;
            if (confirmed) {
              context.read<HistoryBloc>().add(
                    HistoryWorkoutDeleted(widget.initialWorkout.id ?? ''),
                  );
              Navigator.of(context).pop();
              showToast(context, t('Workout deleted'));
            }
          },
        ),
      ],
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return '${s[0].toUpperCase()}${s.substring(1)}';
}
