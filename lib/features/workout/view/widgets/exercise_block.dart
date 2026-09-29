// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/model_extras.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../library/view/bar_weight_editor.dart';
import '../../../library/view/exercise_media.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_entry_view.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';
import '../sheets/exercise_note_sheet.dart';
import 'set_row.dart';
import 'side_rows.dart';

/// Renders a full exercise block during an active workout session.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 76-495 (ExerciseBlock).
///
/// UI-08 Architectural Rule:
/// The sets inside one exercise are a bounded list (typically <= 10),
/// rendered in a Column inside this ExerciseBlock. The unbounded list,
/// which is the list of exercise blocks in the workout session, is handled
/// by ListView.builder in the active workout screen (Plan 03-16).
class ExerciseBlock extends StatelessWidget {
  const ExerciseBlock({
    super.key,
    required this.entryIdx,
    this.compact = false,
    this.dense = false,
    this.onShowDetail,
    this.onShowHistory,
    this.onProgressionSettings,
    this.onSwap,
    this.onMoveUp,
    this.onMoveDown,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.onRemoveExercise,
    this.onPairPrev,
    this.onPairNext,
  });

  final int entryIdx;
  final bool compact;
  final bool dense;
  final VoidCallback? onShowDetail;
  final VoidCallback? onShowHistory;
  final VoidCallback? onProgressionSettings;
  final VoidCallback? onSwap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onRemoveExercise;
  final VoidCallback? onPairPrev;
  final VoidCallback? onPairNext;

  void _openMore(
    BuildContext context, {
    required WorkoutEntryView view,
    required WorkoutEntry entry,
    required String exName,
  }) {
    final bool hasNote = entry.note != null && entry.note!.isNotEmpty;
    final String? lastDate = view.last?.d;

    showMenuSheet(
      context,
      title: exName,
      items: <MenuItemSpec>[
        MenuItemSpec(
          icon: 'pencil',
          label: hasNote ? t('Edit note') : t('Add note'),
          sub: hasNote ? entry.note : null,
          onTap: () => showExerciseNoteSheet(context, entryIdx),
        ),
        MenuItemSpec(
          icon: 'info',
          label: t('Details'),
          onTap: () => onShowDetail?.call(),
        ),
        MenuItemSpec(
          icon: 'history',
          label: t('History'),
          sub: (view.last != null && lastDate != null)
              ? '${t('Last time')} ${fmtDate(lastDate)}'
              : null,
          onTap: () => onShowHistory?.call(),
        ),
        if (onProgressionSettings != null)
          MenuItemSpec(
            icon: 'chartLine',
            label: t('Progression settings'),
            sub: view.guidance != null ? t(view.guidance!.policyLabel) : null,
            onTap: () => onProgressionSettings?.call(),
          ),
        if (view.barInfo != null)
          MenuItemSpec(
            icon: 'dumbbell',
            label: t('Bar weight'),
            sub: view.barInfo!.text,
            onTap: () => showBarWeightSheet(context, view.ex),
          ),
        MenuItemSpec(
          icon: 'flame',
          label: t('Add warm-up set'),
          onTap: () => context.read<WorkoutBloc>().add(WorkoutWarmupAdded(entryIdx)),
        ),
        if (onPairPrev != null)
          MenuItemSpec(
            icon: 'link',
            label: t('Make superset with previous'),
            onTap: () => onPairPrev?.call(),
          ),
        if (onPairNext != null)
          MenuItemSpec(
            icon: 'link',
            label: t('Make superset with next'),
            onTap: () => onPairNext?.call(),
          ),
        if (onSwap != null)
          MenuItemSpec(
            icon: 'shuffle',
            label: t('Swap exercise'),
            onTap: () => onSwap?.call(),
          ),
        if (onMoveUp != null)
          MenuItemSpec(
            icon: 'chevronUp',
            label: t('Move up'),
            disabled: !canMoveUp,
            onTap: () => onMoveUp?.call(),
          ),
        if (onMoveDown != null)
          MenuItemSpec(
            icon: 'chevronDown',
            label: t('Move down'),
            disabled: !canMoveDown,
            onTap: () => onMoveDown?.call(),
          ),
        if (onRemoveExercise != null)
          MenuItemSpec(
            icon: 'trash',
            label: t('Remove exercise'),
            danger: true,
            onTap: () => onRemoveExercise?.call(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final String unit = context.select<GymStateCubit, String>(
      (GymStateCubit c) => c.state.unit ?? 'kg',
    );

    return BlocSelector<WorkoutBloc, WorkoutState, ({
      WorkoutEntryView view,
      WorkoutEntry entry,
      bool setShortcuts,
      bool pairButtons,
    })?>(
      selector: (WorkoutState state) {
        if (state is! WorkoutRunning) return null;
        if (entryIdx < 0 || entryIdx >= state.active.entries!.length) return null;
        final WorkoutEntryView? view =
            entryIdx < state.entryViews.length ? state.entryViews[entryIdx] : null;
        final WorkoutEntry entry = state.active.entries![entryIdx];
        if (view == null) return null;

        return (
          view: view,
          entry: entry,
          setShortcuts: state.wc.setShortcuts,
          pairButtons: state.wc.pairButtons,
        );
      },
      builder: (BuildContext context, ({
        WorkoutEntryView view,
        WorkoutEntry entry,
        bool setShortcuts,
        bool pairButtons,
      })? data) {
        if (data == null) return const SizedBox.shrink();

        final WorkoutEntryView view = data.view;
        final WorkoutEntry entry = data.entry;
        final bool setShortcuts = data.setShortcuts;
        final bool pairButtons = data.pairButtons;

        final List<SetEntry> sets = entry.sets ?? const <SetEntry>[];
        final RoutineExercise? cfg = entry.target;
        final String exName = catalogue.exerciseNameFor(view.ex);

        final int col1Flex = view.timed ? 10 : (view.col3 != null ? 14 : 14);
        final int col2Flex = view.timed ? 14 : (view.col3 != null ? 11 : 10);
        final int col3Flex = 7;

        String whyText = '';
        if (view.guidance?.why != null) {
          final Object? why = view.guidance!.why;
          if (why is List && why.isNotEmpty) {
            whyText = t(why[0].toString(), why.sublist(1));
          } else {
            whyText = t(why.toString());
          }
        }

        final bool isDeload = view.guidance?.kind == 'deload';
        final bool isUp = view.guidance?.kind == 'up';

        final String? lastDate = view.last?.d;
        final String targetTag = catalogue.muscleName[view.ex.tg] ?? view.ex.tg ?? view.ex.bp;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!dense)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExerciseMedia(
                  key: ValueKey<String>(view.ex.id),
                  ex: view.ex,
                  compact: compact,
                  minimizable: true,
                ),
              ),

            // Header title row + note & more icons
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    exName,
                    style: TextStyle(
                      fontSize: (compact || dense) ? 17.0 : 20.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  IconButton(
                    icon: AppIcon('pencil', size: 18.0, color: palette.acc),
                    tooltip: t('Edit note'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                    onPressed: () => showExerciseNoteSheet(context, entryIdx),
                  ),
                IconButton(
                  icon: const AppIcon('more', size: 20.0),
                  tooltip: t('More'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  onPressed: () => _openMore(
                    context,
                    view: view,
                    entry: entry,
                    exName: exName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),

            // Superset pairing shortcut buttons
            if (pairButtons && !compact && !dense && (onPairPrev != null || onPairNext != null)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: <Widget>[
                    if (onPairPrev != null)
                      AppButton(
                        label: Text(t('Make superset with previous')),
                        icon: 'link',
                        variant: AppButtonVariant.tinted,
                        small: true,
                        onPressed: onPairPrev,
                      ),
                    if (onPairNext != null)
                      AppButton(
                        label: Text(t('Make superset with next')),
                        icon: 'link',
                        variant: AppButtonVariant.tinted,
                        small: true,
                        onPressed: onPairNext,
                      ),
                  ],
                ),
              ),
            ],

            // Detail tags, notes, last time, guidance (omitted in dense mode)
            if (!dense) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: <Widget>[
                    if (view.cardio)
                      AppTag(
                        label: t('Cardio'),
                        icon: 'figureRun',
                        isAccent: true,
                      ),
                    if (!view.cardio && !view.timed && view.perSide)
                      AppTag(
                        label: t('Per side'),
                        icon: 'shuffle',
                        isAccent: true,
                      ),
                    AppTag(
                      label: t(targetTag),
                    ),
                    if (view.ex.eq.isNotEmpty)
                      AppTag(
                        label: t(view.ex.eq),
                      ),
                    if (view.best > 0)
                      AppTag(
                        label: '${t('Best:')} ${fmtNum(view.best)} $unit',
                      ),
                  ],
                ),
              ),
              if (cfg?.note != null && cfg!.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    cfg.note!,
                    style: TextStyle(fontSize: 13.0, color: palette.muted),
                  ),
                ),
              if (view.standingNote != null && view.standingNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppIcon('info', size: 13.0, color: palette.muted),
                      const SizedBox(width: 5.0),
                      Expanded(
                        child: Text(
                          view.standingNote!,
                          style: TextStyle(fontSize: 13.0, color: palette.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              if (view.pinnedNote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppIcon('flag', size: 13.0, color: palette.yellow),
                      const SizedBox(width: 5.0),
                      Expanded(
                        child: Text(
                          '${t('From {0}:', <Object?>[
                                view.pinnedNote!.d != null
                                    ? fmtDate(view.pinnedNote!.d!, withYear: true)
                                    : '',
                              ])} ${view.pinnedNote!.note ?? ''}',
                          style: TextStyle(fontSize: 13.0, color: palette.yellow),
                        ),
                      ),
                    ],
                  ),
                ),
              if (entry.note != null && entry.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    entry.note!,
                    style: TextStyle(fontSize: 13.0, color: palette.acc),
                  ),
                ),
              if (view.last != null && lastDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '${t('Last time')} (${fmtDate(lastDate)}): ${view.lastLabel ?? ''}',
                    style: TextStyle(fontSize: 13.0, color: palette.dim),
                  ),
                ),
              if (view.barInfo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: () => showBarWeightSheet(context, view.ex),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppIcon('dumbbell', size: 12.0, color: palette.dim),
                        const SizedBox(width: 5.0),
                        Text(
                          view.barInfo!.text,
                          style: TextStyle(fontSize: 13.0, color: palette.dim),
                        ),
                      ],
                    ),
                  ),
                ),
              if (view.guidance != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.0),
                    onTap: onProgressionSettings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppIcon(
                            isDeload ? 'arrowDown' : (isUp ? 'arrowUp' : 'lightbulb'),
                            size: 14.0,
                            color: isDeload ? palette.yellow : palette.acc,
                          ),
                          const SizedBox(width: 7.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13.0,
                                  height: 1.38,
                                  color: isDeload ? palette.yellow : palette.acc,
                                ),
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: t(view.guidance!.policyLabel),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (whyText.isNotEmpty) ...<InlineSpan>[
                                    const TextSpan(text: ' · '),
                                    TextSpan(text: whyText),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],

            // The sets card
            Container(
              margin: const EdgeInsets.only(top: 6.0),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: palette.sep),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Column header row matching .sethead
                  Row(
                    children: <Widget>[
                      const SizedBox(width: 32.0), // matches 24px .n + 8px gap
                      Expanded(
                        flex: col1Flex,
                        child: Center(
                          child: Text(
                            view.col1.header,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ),
                      if (view.col2 != null) ...<Widget>[
                        const SizedBox(width: 6.0),
                        Expanded(
                          flex: col2Flex,
                          child: Center(
                            child: Text(
                              view.col2!.header,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (view.col3 != null) ...<Widget>[
                        const SizedBox(width: 6.0),
                        Expanded(
                          flex: col3Flex,
                          child: Center(
                            child: Text(
                              view.col3!.header,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 32.0), // matches 24px check + 8px gap
                    ],
                  ),
                  const SizedBox(height: 4.0),

                  // Bounded set rows
                  for (int i = 0; i < sets.length; i++) ...<Widget>[
                    if (view.perSide &&
                        !(i < view.isWarmup.length && view.isWarmup[i]) &&
                        (i < view.isSide.length && view.isSide[i]))
                      SideRows(
                        entryIdx: entryIdx,
                        setIdx: i,
                      )
                    else
                      SetRow(
                        entryIdx: entryIdx,
                        setIdx: i,
                      ),
                  ],

                  const SizedBox(height: 8.0),

                  // Sets footer buttons
                  if (setShortcuts)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: <Widget>[
                        AppButton(
                          label: Text(t('Add warm-up set')),
                          icon: 'flame',
                          small: true,
                          onPressed: () => context.read<WorkoutBloc>().add(
                                WorkoutWarmupAdded(entryIdx),
                              ),
                        ),
                        AppButton(
                          label: Text(t('Remove set')),
                          icon: 'minus',
                          small: true,
                          onPressed: sets.length <= 1
                              ? null
                              : () => context.read<WorkoutBloc>().add(
                                    WorkoutSetRemoved(entryIdx),
                                  ),
                        ),
                        AppButton(
                          label: Text(t('Add set')),
                          icon: 'plus',
                          small: true,
                          onPressed: () => context.read<WorkoutBloc>().add(
                                WorkoutSetAdded(entryIdx),
                              ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: Text(t('Add set')),
                        icon: 'plus',
                        small: true,
                        onPressed: () => context.read<WorkoutBloc>().add(
                              WorkoutSetAdded(entryIdx),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
