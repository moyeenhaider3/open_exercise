// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/workout.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/rows.dart';
import '../../../core/ui_kit/toast.dart';
import '../../library/view/exercise_detail_sheet.dart';
import '../../library/view/exercise_history_sheet.dart';
import '../../library/view/exercise_picker_sheet.dart';
import '../../plan/view/sheets/ex_config_sheet.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../data/active_exercise_swap.dart';
import '../data/active_workout_order.dart';
import 'sheets/add_routine_to_session_sheet.dart';
import 'sheets/remove_exercise_sheet.dart';
import 'sheets/rename_workout_sheet.dart';
import 'sheets/session_note_sheet.dart';
import 'sheets/swap_choice_sheet.dart';
import 'widgets/exercise_block.dart';

// Swipe gesture thresholds matching openGym constants (Workout.jsx lines 26-27).
const double kSwipeMinDistance = 48.0;
const double kSwipeAxisRatio = 1.25;

/// View rendered for an active workout in Cards, List, or Compact layout.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 517-1135 (ActiveWorkout).
class ActiveWorkoutView extends StatefulWidget {
  const ActiveWorkoutView({
    super.key,
    required this.state,
  });

  final WorkoutRunning state;

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  double _dragDelta = 0.0;

  void _openLayoutMenu(BuildContext context, String currentView) {
    showMenuSheet(
      context,
      title: t('Layout'),
      items: <MenuItemSpec>[
        MenuItemSpec(
          icon: 'clipboard',
          label: t('Cards'),
          onTap: () => context.read<WorkoutBloc>().add(const WorkoutViewChanged('cards')),
        ),
        MenuItemSpec(
          icon: 'list',
          label: t('List'),
          onTap: () => context.read<WorkoutBloc>().add(const WorkoutViewChanged('list')),
        ),
        MenuItemSpec(
          icon: 'minimize',
          label: t('Compact'),
          onTap: () => context.read<WorkoutBloc>().add(const WorkoutViewChanged('compact')),
        ),
      ],
    );
  }

  void _openViewMenu(BuildContext context, String currentView) {
    final Map<String, String> layoutLabels = <String, String>{
      'cards': t('Cards'),
      'list': t('List'),
      'compact': t('Compact'),
    };

    showMenuSheet(
      context,
      items: <MenuItemSpec>[
        MenuItemSpec(
          icon: 'pencil',
          label: t('Rename workout'),
          onTap: () => showRenameWorkoutSheet(context),
        ),
        MenuItemSpec(
          icon: 'plus',
          label: t('Add routine'),
          sub: t('Bring another routine into this session'),
          onTap: () => showAddRoutineToSessionSheet(context),
        ),
        MenuItemSpec(
          icon: 'list',
          label: t('Layout'),
          sub: layoutLabels[currentView] ?? layoutLabels['cards'],
          onTap: () => _openLayoutMenu(context, currentView),
        ),
      ],
    );
  }

  Future<void> _discardWorkout(BuildContext context) async {
    final bool confirmed = await showConfirmSheet(
      context,
      title: t('Discard workout?'),
      message: t('The sets you logged in this session will be lost.'),
      confirmText: t('Discard'),
      danger: true,
    );
    if (confirmed && context.mounted) {
      context.read<WorkoutBloc>().add(const WorkoutDiscarded());
      context.go(AppRoutes.home);
    }
  }

  Future<void> _swapExercise(BuildContext context, int idx) async {
    final WorkoutRunning st = widget.state;
    final List<WorkoutEntry> entries = st.active.entries ?? const <WorkoutEntry>[];
    if (idx < 0 || idx >= entries.length) return;
    final WorkoutEntry entry = entries[idx];

    showExercisePickerSheet(
      context,
      onPick: (ExerciseDef newEx, bool quick, PickerHandle picker) async {
        picker.close();
        final SwapOptions? options = await showSwapChoiceSheet(context, current: entry);
        if (options == null || !context.mounted) return;

        if (quick) {
          final JsEngineService engine = context.read<JsEngineService>();
          final RoutineExercise cfg = engine.history.defaultConfig(newEx.id);
          context.read<WorkoutBloc>().add(
                WorkoutExerciseSwapped(
                  index: idx,
                  exId: newEx.id,
                  cfg: cfg,
                  options: options,
                ),
              );
        } else {
          showExConfigSheet(
            context,
            ex: newEx,
            onSave: (RoutineExercise cfg) {
              context.read<WorkoutBloc>().add(
                    WorkoutExerciseSwapped(
                      index: idx,
                      exId: newEx.id,
                      cfg: cfg,
                      options: options,
                    ),
                  );
            },
          );
        }
      },
    );
  }

  void _addExercise(BuildContext context) {
    final WorkoutRunning st = widget.state;
    final JsEngineService engine = context.read<JsEngineService>();
    final GymState gymState = context.read<GymStateCubit>().state;
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();

    final String? curRid = st.active.entries?.elementAtOrNull(st.cur)?.rid;
    final Routine? routine = (curRid != null && gymState.routines != null)
        ? gymState.routines!.where((Routine r) => r.id == curRid).firstOrNull
        : null;
    final bool freestyle = (routine == null);

    showExercisePickerSheet(
      context,
      onPick: (ExerciseDef ex, bool quick, PickerHandle picker) {
        final RoutineExercise seed = freestyle
            ? engine.history.freestyleConfig(
                gymState,
                engine.history.defaultConfig(ex.id),
              )
            : engine.history.defaultConfig(ex.id);

        if (quick) {
          context.read<WorkoutBloc>().add(
                WorkoutExerciseAdded(
                  exId: ex.id,
                  cfg: seed,
                  quick: true,
                ),
              );
          final String routineName = routine?.name ?? t('Freestyle');
          showToast(
            context,
            t('“{0}” added to {1}', <Object?>[
              capWords(catalogue.exerciseNameFor(ex)),
              routineName,
            ]),
          );
        } else {
          showExConfigSheet(
            context,
            ex: ex,
            initial: seed,
            routine: routine,
            onSave: (RoutineExercise cfg) {
              context.read<WorkoutBloc>().add(
                    WorkoutExerciseAdded(
                      exId: ex.id,
                      cfg: cfg,
                    ),
                  );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();

    final WorkoutRunning st = widget.state;
    final Workout active = st.active;
    final List<WorkoutEntry> entries = active.entries ?? const <WorkoutEntry>[];
    final List<List<int>> units = st.units;
    final int cur = st.cur;
    final int unitIdx = st.unitIdx;
    final List<int> unit = st.currentUnit;
    final bool isSuperset = unit.length > 1;

    final String workoutView = st.view;
    final bool listMode = workoutView == 'list' || workoutView == 'compact';
    final bool dense = workoutView == 'compact';
    final int done = st.setsDone;
    final int total = st.setsTotal;

    final bool canMoveUp = canMoveActiveWorkoutUnit(active, cur, -1, engine.history);
    final bool canMoveDown = canMoveActiveWorkoutUnit(active, cur, 1, engine.history);

    final int exDone = st.exercisesDone;
    final bool allDone = entries.isNotEmpty && exDone == entries.length;

    final Widget header = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: palette.sep, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const AppIcon('xmark', size: 20.0),
                tooltip: t('Discard'),
                onPressed: () => _discardWorkout(context),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      active.name ?? '',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _Elapsed(start: active.start),
                        Text(
                          ' · ${t('{0} sets', <Object?>['$done/$total'])}',
                          style: TextStyle(fontSize: 13.0, color: palette.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const AppIcon('more', size: 20.0),
                    tooltip: t('Workout view'),
                    onPressed: () => _openViewMenu(context, workoutView),
                  ),
                  IconButton(
                    icon: AppIcon('check', size: 22.0, color: palette.acc),
                    tooltip: t('Finish'),
                    onPressed: () => context.read<WorkoutBloc>().add(const WorkoutFinishRequested()),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.0),
            child: LinearProgressIndicator(
              value: total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0,
              backgroundColor: palette.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(palette.acc),
              minHeight: 3.0,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            header,
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AppIcon('shuffle', size: 48.0, color: palette.dim),
                            const SizedBox(height: 12.0),
                            Text(
                              t('Freestyle workout — add your first exercise.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15.0, color: palette.muted),
                            ),
                            const SizedBox(height: 16.0),
                            AppButton(
                              label: Text(t('Add exercise')),
                              icon: 'plus',
                              variant: AppButtonVariant.primary,
                              onPressed: () => _addExercise(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  : listMode
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          itemCount: units.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == units.length) {
                              return _buildBottomControls(
                                context,
                                palette: palette,
                                listMode: listMode,
                                unitIdx: unitIdx,
                                unitsCount: units.length,
                                canMoveUp: canMoveUp,
                                canMoveDown: canMoveDown,
                                cur: cur,
                                unit: unit,
                                hasNote: active.note != null && active.note!.isNotEmpty,
                                allDone: allDone,
                                exDone: exDone,
                                totalEntries: entries.length,
                              );
                            }

                            final List<int> u = units[index];
                            final bool multi = u.length > 1;
                            final bool isCur = u.contains(cur);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        multi
                                            ? t('Superset {0} / {1}', <Object?>[index + 1, units.length])
                                            : t('Exercise {0} / {1}', <Object?>[index + 1, units.length]),
                                        style: TextStyle(fontSize: 13.0, color: palette.muted),
                                      ),
                                      if (isCur)
                                        AppTag(
                                          label: t('Current'),
                                          isAccent: true,
                                        )
                                      else
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6.0),
                                          onTap: () => context.read<WorkoutBloc>().add(WorkoutUnitFocused(u[0])),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                            decoration: BoxDecoration(
                                              color: palette.surface2,
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: Text(
                                              t('Set current'),
                                              style: TextStyle(fontSize: 12.0, color: palette.muted),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6.0),
                                  if (multi)
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: palette.acc, width: 1.5),
                                        borderRadius: BorderRadius.circular(16.0),
                                      ),
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Expanded(
                                                child: Row(
                                                  children: <Widget>[
                                                    AppIcon('link', size: 14.0, color: palette.acc),
                                                    const SizedBox(width: 5.0),
                                                    Expanded(
                                                      child: Text(
                                                        t('Superset · do these back-to-back, rest when done'),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 12.0, color: palette.acc),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              AppButton(
                                                label: Text(t('Unpair')),
                                                icon: 'link',
                                                small: true,
                                                variant: AppButtonVariant.ghost,
                                                onPressed: () => context.read<WorkoutBloc>().add(WorkoutUnpaired(u[0])),
                                              ),
                                            ],
                                          ),
                                          for (int k = 0; k < u.length; k++) ...<Widget>[
                                            if (k > 0)
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Center(
                                                  child: Text(
                                                    '+',
                                                    style: TextStyle(
                                                      fontSize: 20.0,
                                                      fontWeight: FontWeight.bold,
                                                      color: palette.acc,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ExerciseBlock(
                                              entryIdx: u[k],
                                              compact: true,
                                              dense: dense,
                                              onShowDetail: () {
                                                final ExerciseDef ex = catalogue.lookup(
                                                  context.read<GymStateCubit>().state,
                                                  entries[u[k]].id ?? '',
                                                );
                                                showExerciseDetailSheet(context, ex);
                                              },
                                              onShowHistory: () => showExerciseHistorySheet(
                                                context,
                                                entries[u[k]].id ?? '',
                                              ),
                                              onProgressionSettings: () => _openProgression(context, u[k]),
                                              onSwap: () => _swapExercise(context, u[k]),
                                              onMoveUp: () => context.read<WorkoutBloc>().add(
                                                    WorkoutUnitMoved(at: u[k], direction: -1),
                                                  ),
                                              onMoveDown: () => context.read<WorkoutBloc>().add(
                                                    WorkoutUnitMoved(at: u[k], direction: 1),
                                                  ),
                                              canMoveUp: canMoveActiveWorkoutUnit(active, u[k], -1, engine.history),
                                              canMoveDown: canMoveActiveWorkoutUnit(active, u[k], 1, engine.history),
                                              onRemoveExercise: () => confirmRemoveExercise(context, u[k]),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    ExerciseBlock(
                                      entryIdx: u[0],
                                      dense: dense,
                                      onShowDetail: () {
                                        final ExerciseDef ex = catalogue.lookup(
                                          context.read<GymStateCubit>().state,
                                          entries[u[0]].id ?? '',
                                        );
                                        showExerciseDetailSheet(context, ex);
                                      },
                                      onShowHistory: () => showExerciseHistorySheet(
                                        context,
                                        entries[u[0]].id ?? '',
                                      ),
                                      onProgressionSettings: () => _openProgression(context, u[0]),
                                      onSwap: () => _swapExercise(context, u[0]),
                                      onMoveUp: () => context.read<WorkoutBloc>().add(
                                            WorkoutUnitMoved(at: u[0], direction: -1),
                                          ),
                                      onMoveDown: () => context.read<WorkoutBloc>().add(
                                            WorkoutUnitMoved(at: u[0], direction: 1),
                                          ),
                                      canMoveUp: canMoveActiveWorkoutUnit(active, u[0], -1, engine.history),
                                      canMoveDown: canMoveActiveWorkoutUnit(active, u[0], 1, engine.history),
                                      onRemoveExercise: () => confirmRemoveExercise(context, u[0]),
                                      onPairPrev: u[0] > 0
                                          ? () => context.read<WorkoutBloc>().add(
                                                WorkoutPaired(first: u[0] - 1, second: u[0]),
                                              )
                                          : null,
                                      onPairNext: u[0] < entries.length - 1
                                          ? () => context.read<WorkoutBloc>().add(
                                                WorkoutPaired(first: u[0], second: u[0] + 1),
                                              )
                                          : null,
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (_) {
                            _dragDelta = 0.0;
                          },
                          onHorizontalDragUpdate: (DragUpdateDetails details) {
                            _dragDelta += details.primaryDelta ?? 0.0;
                          },
                          onHorizontalDragEnd: (DragEndDetails details) {
                            final double vel = details.primaryVelocity ?? 0.0;
                            final bool swipeLeft = _dragDelta < -kSwipeMinDistance || vel < -200.0;
                            final bool swipeRight = _dragDelta > kSwipeMinDistance || vel > 200.0;
                            if (swipeLeft) {
                              context.read<WorkoutBloc>().add(const WorkoutUnitNavigated(1));
                            } else if (swipeRight) {
                              context.read<WorkoutBloc>().add(const WorkoutUnitNavigated(-1));
                            }
                            _dragDelta = 0.0;
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  isSuperset
                                      ? t('Superset {0} / {1}', <Object?>[unitIdx + 1, units.length])
                                      : t('Exercise {0} / {1}', <Object?>[unitIdx + 1, units.length]),
                                  style: TextStyle(fontSize: 13.0, color: palette.muted),
                                ),
                                const SizedBox(height: 6.0),
                                if (isSuperset)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: palette.acc, width: 1.5),
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Expanded(
                                              child: Row(
                                                children: <Widget>[
                                                  AppIcon('link', size: 14.0, color: palette.acc),
                                                  const SizedBox(width: 5.0),
                                                  Expanded(
                                                    child: Text(
                                                      t('Superset · do these back-to-back, rest when done'),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 12.0, color: palette.acc),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            AppButton(
                                              label: Text(t('Unpair')),
                                              icon: 'link',
                                              small: true,
                                              variant: AppButtonVariant.ghost,
                                              onPressed: () => context.read<WorkoutBloc>().add(WorkoutUnpaired(cur)),
                                            ),
                                          ],
                                        ),
                                        for (int k = 0; k < unit.length; k++) ...<Widget>[
                                          if (k > 0)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Center(
                                                child: Text(
                                                  '+',
                                                  style: TextStyle(
                                                    fontSize: 20.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: palette.acc,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ExerciseBlock(
                                            entryIdx: unit[k],
                                            compact: true,
                                            onShowDetail: () {
                                              final ExerciseDef ex = catalogue.lookup(
                                                context.read<GymStateCubit>().state,
                                                entries[unit[k]].id ?? '',
                                              );
                                              showExerciseDetailSheet(context, ex);
                                            },
                                            onShowHistory: () => showExerciseHistorySheet(
                                              context,
                                              entries[unit[k]].id ?? '',
                                            ),
                                            onProgressionSettings: () => _openProgression(context, unit[k]),
                                            onSwap: () => _swapExercise(context, unit[k]),
                                            onMoveUp: () => context.read<WorkoutBloc>().add(
                                                  WorkoutUnitMoved(at: unit[k], direction: -1),
                                                ),
                                            onMoveDown: () => context.read<WorkoutBloc>().add(
                                                  WorkoutUnitMoved(at: unit[k], direction: 1),
                                                ),
                                            canMoveUp: canMoveActiveWorkoutUnit(active, unit[k], -1, engine.history),
                                            canMoveDown: canMoveActiveWorkoutUnit(active, unit[k], 1, engine.history),
                                            onRemoveExercise: () => confirmRemoveExercise(context, unit[k]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                else
                                  ExerciseBlock(
                                    entryIdx: cur,
                                    onShowDetail: () {
                                      final ExerciseDef ex = catalogue.lookup(
                                        context.read<GymStateCubit>().state,
                                        entries[cur].id ?? '',
                                      );
                                      showExerciseDetailSheet(context, ex);
                                    },
                                    onShowHistory: () => showExerciseHistorySheet(
                                      context,
                                      entries[cur].id ?? '',
                                    ),
                                    onProgressionSettings: () => _openProgression(context, cur),
                                    onSwap: () => _swapExercise(context, cur),
                                    onMoveUp: () => context.read<WorkoutBloc>().add(
                                          WorkoutUnitMoved(at: cur, direction: -1),
                                        ),
                                    onMoveDown: () => context.read<WorkoutBloc>().add(
                                          WorkoutUnitMoved(at: cur, direction: 1),
                                        ),
                                    canMoveUp: canMoveUp,
                                    canMoveDown: canMoveDown,
                                    onRemoveExercise: () => confirmRemoveExercise(context, cur),
                                    onPairPrev: cur > 0
                                        ? () => context.read<WorkoutBloc>().add(
                                              WorkoutPaired(first: cur - 1, second: cur),
                                            )
                                        : null,
                                    onPairNext: cur < entries.length - 1
                                        ? () => context.read<WorkoutBloc>().add(
                                              WorkoutPaired(first: cur, second: cur + 1),
                                            )
                                        : null,
                                  ),
                                const SizedBox(height: 12.0),
                                _buildBottomControls(
                                  context,
                                  palette: palette,
                                  listMode: listMode,
                                  unitIdx: unitIdx,
                                  unitsCount: units.length,
                                  canMoveUp: canMoveUp,
                                  canMoveDown: canMoveDown,
                                  cur: cur,
                                  unit: unit,
                                  hasNote: active.note != null && active.note!.isNotEmpty,
                                  allDone: allDone,
                                  exDone: exDone,
                                  totalEntries: entries.length,
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProgression(BuildContext context, int idx) {
    final WorkoutRunning st = widget.state;
    final List<WorkoutEntry> entries = st.active.entries ?? const <WorkoutEntry>[];
    if (idx < 0 || idx >= entries.length) return;
    final WorkoutEntry entry = entries[idx];
    final String entryId = entry.id ?? '';
    final String activeId = st.active.id ?? '';
    final int entryCount = entries.length;

    final GymState gymState = context.read<GymStateCubit>().state;
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final ExerciseDef ex = catalogue.lookup(gymState, entryId);
    final Routine? routine = (entry.rid != null && gymState.routines != null)
        ? gymState.routines!.where((Routine r) => r.id == entry.rid).firstOrNull
        : null;

    showExConfigSheet(
      context,
      ex: ex,
      existing: entry.target,
      routine: routine,
      onSave: (RoutineExercise cfg) {
        context.read<WorkoutBloc>().add(
              WorkoutProgressionConfigured(
                activeId: activeId,
                entryIdx: idx,
                entryId: entryId,
                entryCount: entryCount,
                cfg: cfg,
              ),
            );
      },
    );
  }

  Widget _buildBottomControls(
    BuildContext context, {
    required AppPalette palette,
    required bool listMode,
    required int unitIdx,
    required int unitsCount,
    required bool canMoveUp,
    required bool canMoveDown,
    required int cur,
    required List<int> unit,
    required bool hasNote,
    required bool allDone,
    required int exDone,
    required int totalEntries,
  }) {
    final WorkoutRunning st = widget.state;
    final bool showExerciseButtons = st.wc.exerciseButtons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!listMode) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: Text(t('Prev')),
                  icon: 'chevronLeft',
                  onPressed: unitIdx <= 0
                      ? null
                      : () => context.read<WorkoutBloc>().add(const WorkoutUnitNavigated(-1)),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: AppButton(
                  label: Text(t('Next')),
                  trailingIcon: 'chevronRight',
                  onPressed: (unitIdx < 0 || unitIdx >= unitsCount - 1)
                      ? null
                      : () => context.read<WorkoutBloc>().add(const WorkoutUnitNavigated(1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
        ],

        if (showExerciseButtons && listMode && totalEntries > 0) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              t('Move, swap and remove below act on the exercise marked {0}.', <Object?>[t('Current')]),
              style: TextStyle(fontSize: 13.0, color: palette.muted),
            ),
          ),
        ],

        AppButton(
          label: Text(t('Add exercise')),
          icon: 'plus',
          onPressed: () => _addExercise(context),
        ),

        if (showExerciseButtons && totalEntries > 0) ...<Widget>[
          const SizedBox(height: 6.0),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: Text(t('Move up')),
                  icon: 'chevronUp',
                  small: true,
                  onPressed: !canMoveUp
                      ? null
                      : () => context.read<WorkoutBloc>().add(WorkoutUnitMoved(at: cur, direction: -1)),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: AppButton(
                  label: Text(t('Move down')),
                  trailingIcon: 'chevronDown',
                  small: true,
                  onPressed: !canMoveDown
                      ? null
                      : () => context.read<WorkoutBloc>().add(WorkoutUnitMoved(at: cur, direction: 1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Center(
            child: AppButton(
              label: Text(t('Swap exercise')),
              icon: 'shuffle',
              small: true,
              onPressed: () => _swapExercise(context, cur),
            ),
          ),
          const SizedBox(height: 6.0),
          Center(
            child: AppButton(
              label: Text(t('Remove exercise')),
              icon: 'minus',
              small: true,
              variant: AppButtonVariant.plain,
              onPressed: () => showRemoveExerciseChooser(context, unit),
            ),
          ),
        ],

        const SizedBox(height: 10.0),
        Center(
          child: AppButton(
            label: Text(hasNote ? t('Edit session note') : t('Add session note')),
            icon: 'pencil',
            small: true,
            variant: hasNote ? AppButtonVariant.tinted : AppButtonVariant.plain,
            onPressed: () => showSessionNoteSheet(context),
          ),
        ),
        const SizedBox(height: 10.0),
        if (allDone)
          AppButton(
            label: Text(t('Finish workout')),
            variant: AppButtonVariant.primary,
            icon: 'flag',
            onPressed: () => context.read<WorkoutBloc>().add(const WorkoutFinishRequested()),
          )
        else
          AppButton(
            label: Text(
              t('Finish workout early · {0} exercises', <Object?>['$exDone/$totalEntries']),
            ),
            variant: AppButtonVariant.ghost,
            onPressed: () => context.read<WorkoutBloc>().add(const WorkoutFinishRequested()),
          ),
        const SizedBox(height: 32.0),
      ],
    );
  }
}

/// Session elapsed clock widget updating every 1s via Timer.periodic (D-02a).
class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.start});

  final num? start;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  Timer? _timer;
  String _timeStr = '0:00';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    if (widget.start == null) return;
    final int startMs = widget.start!.toInt();
    final int elapsedSec = ((DateTime.now().millisecondsSinceEpoch - startMs) / 1000).floor();
    final int s = elapsedSec < 0 ? 0 : elapsedSec;
    final int minutes = s ~/ 60;
    final int seconds = s % 60;
    final String next = '$minutes:${seconds.toString().padLeft(2, '0')}';
    if (next != _timeStr && mounted) {
      setState(() {
        _timeStr = next;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _Elapsed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start) {
      _update();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeStr,
      style: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: AppPalette.of(context).muted,
      ),
    );
  }
}
