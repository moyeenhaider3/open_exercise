// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backup/auto_backup_sync.dart';
import '../../../core/body_map/body_map.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/glyphs.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/muscles_js.dart';
import '../../../core/js/modules/progression_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/rows.dart';
import '../../../core/ui_kit/toast.dart';
import '../../library/view/exercise_media.dart';
import '../../library/view/exercise_picker_sheet.dart';
import '../bloc/routine_edit_bloc.dart';
import '../bloc/routine_edit_event.dart';
import '../bloc/routine_edit_state.dart';
import 'sheets/ex_config_sheet.dart';
import 'sheets/glyph_picker_sheet.dart';

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// Routine editing screen.
/// Ported from `../openGym/frontend/src/views/RoutineEdit.jsx`.
class RoutineEditScreen extends StatelessWidget {
  const RoutineEditScreen({
    super.key,
    required this.routineId,
  });

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutineEditBloc>(
      create: (BuildContext ctx) => RoutineEditBloc(
        gymState: ctx.read<GymStateCubit>(),
        engine: ctx.read<JsEngineService>(),
        catalogue: ctx.read<ExerciseCatalogue>(),
        routineId: routineId,
      ),
      child: RoutineEditView(
        key: ValueKey<String>(routineId),
        routineId: routineId,
      ),
    );
  }
}

class RoutineEditView extends StatefulWidget {
  const RoutineEditView({super.key, required this.routineId});

  final String routineId;

  @override
  State<RoutineEditView> createState() => _RoutineEditViewState();
}

class _RoutineEditViewState extends State<RoutineEditView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    // D-06(b): auto-backup on leaving routine editor (openGym RoutineEdit.jsx:317)
    try {
      context.read<AutoBackupSync>().autoBackupNow();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();

    return BlocConsumer<RoutineEditBloc, RoutineEditState>(
      listener: (BuildContext ctx, RoutineEditState state) {
        if (state is RoutineEditMissing) {
          ctx.go(AppRoutes.plan);
          return;
        }
        if (state is RoutineEditReady && state.signal != null) {
          final RoutineEditSignal sig = state.signal!;
          if (sig is RoutineEditNavigateSignal) {
            ctx.go(sig.path);
          } else if (sig is RoutineEditToastSignal) {
            showToast(ctx, sig.message);
          }
        }
      },
      builder: (BuildContext ctx, RoutineEditState state) {
        if (state is! RoutineEditReady) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final Routine routine = state.routine;
        if (_nameController.text.isEmpty && (routine.name ?? '').isNotEmpty) {
          _nameController.text = routine.name!;
        }

        final List<String> repPolicies =
            engine.progression.policiesFor['reps'] ??
                const <String>['linear', 'double', 'off'];
        final Map<String, String> policyName = engine.progression.policyName;
        final Map<String, String> policyDesc = engine.progression.policyDesc;

        final List<SelectOption<String>> progressionOptions = repPolicies
            .map(
              (String p) => SelectOption<String>(
                value: p,
                label: t(policyName[p] ?? p),
                subtitle: t(policyDesc[p] ?? ''),
              ),
            )
            .toList();

        final Widget headerSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Top App Bar / Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const AppIcon('chevronLeft'),
                    tooltip: t('Plan'),
                    onPressed: () => ctx.go(AppRoutes.plan),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                        decoration: InputDecoration(
                          hintText: t('Routine'),
                          hintStyle: TextStyle(color: palette.muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (String val) {
                          ctx.read<RoutineEditBloc>().add(RoutineRenamed(val));
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(glyphOf(routine.emoji)),
                    tooltip: t('Pick an icon'),
                    onPressed: () async {
                      final String? g = await showGlyphPickerSheet(
                        ctx,
                        current: routine.emoji,
                      );
                      if (g != null && ctx.mounted) {
                        ctx
                            .read<RoutineEditBloc>()
                            .add(RoutineGlyphChanged(g));
                      }
                    },
                  ),
                ],
              ),
            ),

            // Progression & Deload Section
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SelectRow<String>(
                    icon: 'chartLine',
                    title: t('Progression'),
                    sheetTitle: t('Progression'),
                    value: routine.prog ?? 'linear',
                    options: progressionOptions,
                    onChanged: (String v) {
                      ctx
                          .read<RoutineEditBloc>()
                          .add(RoutineProgressionPolicyChanged(v));
                    },
                  ),
                  Divider(height: 1, color: palette.surface2),
                  AppRow(
                    icon: 'pause',
                    iconTint: palette.orange,
                    title: Text(t('Exclude from automatic progression')),
                    subtitle: Text(
                      t('Use for planned deloads. Workouts stay in history and statistics.'),
                    ),
                    child: AppSwitch(
                      value: routine.excludeFromProgression,
                      onChanged: (bool v) {
                        ctx
                            .read<RoutineEditBloc>()
                            .add(RoutineExcludeChanged(v));
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                routine.excludeFromProgression
                    ? t('The next regular target continues from the last included workout.')
                    : t('Applies to every exercise in this routine that does not set its own rule.'),
                style: TextStyle(
                  fontSize: 13,
                  color: palette.muted,
                  height: 1.38,
                ),
              ),
            ),

            // Profile Equipment Warning Card
            if (state.missingCount > 0 && state.profile != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.orange),
                ),
                child: Row(
                  children: <Widget>[
                    AppIcon('warning', color: palette.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t(
                          '{0} of {1} exercises need equipment outside "{2}"',
                          <Object?>[
                            state.missingCount,
                            routine.ex?.length ?? 0,
                            state.profile!.name,
                          ],
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Empty state if routine has no exercises
            if ((routine.ex ?? const <RoutineExercise>[]).isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: EmptyState(
                  icon: 'dumbbell',
                  text: t('No exercises yet — add your first one.'),
                ),
              ),
          ],
        );

        final Widget footerSection = Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // What this session hits
              if ((routine.ex ?? const <RoutineExercise>[]).isNotEmpty) ...<Widget>[
                Builder(
                  builder: (BuildContext bCtx) {
                    final Map<String, double> load = engine.muscles.loadOfRoutine(routine);
                    final Map<String, int> levels = engine.muscles.levelsOf(load);
                    final List<String> topMuscles =
                        engine.muscles.rankOf(load).worked.take(6).toList();
                    final Map<String, String> muscleNames = engine.muscles.muscleName;
                    final String? body = bCtx.read<GymStateCubit>().state.body;

                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            t('What this session hits'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.015,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BodyMap(
                            body: body,
                            levels: levels,
                          ),
                          if (topMuscles.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: <Widget>[
                                for (final String slug in topMuscles)
                                  _MuscleChip(label: muscleNames[slug] ?? slug),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Tip Line
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppIcon('link', size: 13, color: palette.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t('Tap the link button on an exercise to superset it with the one above — you’ll do them back-to-back.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Add Exercise Button
              AppButton(
                label: Text(t('Add exercise')),
                icon: 'plus',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  showExercisePickerSheet(
                    ctx,
                    onPick: (ExerciseDef ex, bool quick, PickerHandle picker) {
                      if (quick) {
                        picker.close();
                        final RoutineExercise cfg =
                            engine.history.defaultConfig(ex.id);
                        ctx.read<RoutineEditBloc>().add(
                              RoutineExerciseAdded(
                                exId: ex.id,
                                cfg: cfg,
                                quick: true,
                              ),
                            );
                      } else {
                        picker.close();
                        showExConfigSheet(
                          ctx,
                          ex: ex,
                          routine: routine,
                          onSave: (RoutineExercise cfg) {
                            ctx.read<RoutineEditBloc>().add(
                                  RoutineExerciseAdded(
                                    exId: ex.id,
                                    cfg: cfg,
                                    quick: false,
                                  ),
                                );
                          },
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 10),

              // Copy Routine Button
              AppButton(
                label: Text(t('Copy routine')),
                onPressed: () {
                  ctx.read<RoutineEditBloc>().add(const RoutineCopied());
                },
              ),
              const SizedBox(height: 10),

              // Delete Routine Button
              AppButton(
                label: Text(t('Delete routine')),
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  final bool confirmed = await showConfirmSheet(
                    ctx,
                    title: t('Delete routine?'),
                    message: t(
                      '“{0}” and its exercises will be removed.',
                      <Object?>[routine.name],
                    ),
                    confirmText: t('Delete'),
                    danger: true,
                  );
                  if (confirmed && ctx.mounted) {
                    ctx.read<RoutineEditBloc>().add(const RoutineDeleted());
                  }
                },
              ),
            ],
          ),
        );

        return Scaffold(
          body: SafeArea(
            child: ReorderableListView.builder(
              header: headerSection,
              footer: footerSection,
              itemCount: state.units.length,
              buildDefaultDragHandles: true,
              proxyDecorator: (
                Widget child,
                int index,
                Animation<double> animation,
              ) {
                return Material(
                  elevation: 6,
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                );
              },
              onReorderItem: (int oldIndex, int newIndex) {
                ctx
                    .read<RoutineEditBloc>()
                    .add(RoutineUnitReordered(oldIndex, newIndex));
              },
              itemBuilder: (BuildContext rowCtx, int unitIdx) {
                final List<int> unit = state.units[unitIdx];
                final int firstIdx = unit.first;
                final RoutineExercise firstEx = routine.ex![firstIdx];

                return Container(
                  key: ValueKey<String>('unit_${firstEx.id}_$firstIdx'),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (unit.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 6,
                            top: 4,
                          ),
                          child: Row(
                            children: <Widget>[
                              AppIcon('link', size: 13, color: palette.acc),
                              const SizedBox(width: 5),
                              Text(
                                t('Superset'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.acc,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...unit.map((int i) {
                        final RoutineExercise e = routine.ex![i];
                        final ExerciseDef ex =
                            catalogue.lookup(gymState, e.id ?? '');
                        final bool noEquip =
                            i < state.noEquip.length && state.noEquip[i];
                        final String line =
                            i < state.lines.length ? state.lines[i] : '';
                        final bool inSS = state.inSuperset.contains(i);
                        final bool linkedPrev = i > 0 &&
                            e.sg != null &&
                            routine.ex![i - 1].sg == e.sg;
                        final bool isFirstUnit = state.unitIndex[i] == 0;
                        final bool isLastUnit =
                            state.unitIndex[i] == state.units.length - 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: inSS
                                ? Border(
                                    left: BorderSide(
                                      color: palette.acc,
                                      width: 3.5,
                                    ),
                                  )
                                : null,
                          ),
                          child: Dismissible(
                            key: ValueKey<String>(
                              'row_${e.id}_${e.sg}_${i}_$unitIdx',
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: palette.red,
                              padding: const EdgeInsets.only(right: 20),
                              child: Text(
                                t('Remove from routine'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onDismissed: (_) {
                              ctx
                                  .read<RoutineEditBloc>()
                                  .add(RoutineExerciseRemoved(i));
                            },
                            child: InkWell(
                              onTap: () {
                                showExConfigSheet(
                                  ctx,
                                  ex: ex,
                                  existing: e,
                                  routine: routine,
                                  onSave: (RoutineExercise cfg) {
                                    ctx.read<RoutineEditBloc>().add(
                                          RoutineExerciseConfigured(i, cfg),
                                        );
                                  },
                                  onDelete: () {
                                    ctx
                                        .read<RoutineEditBloc>()
                                        .add(RoutineExerciseRemoved(i));
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: <Widget>[
                                    ExerciseThumb(ex: ex),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _capitalize(
                                              catalogue.exerciseNameFor(ex),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            line,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: palette.muted,
                                            ),
                                          ),
                                          if (e.note != null &&
                                              e.note!.isNotEmpty) ...<Widget>[
                                            const SizedBox(height: 2),
                                            Text(
                                              e.note!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: palette.dim,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (noEquip) ...<Widget>[
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        message: t(
                                          'Needs {0} — not in your active profile',
                                          <Object?>[t(ex.eq)],
                                        ),
                                        child: AppTag(
                                          label: '',
                                          icon: 'warning',
                                          color: palette.orange,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        if (i > 0)
                                          IconButton(
                                            icon:
                                                const AppIcon('link', size: 15),
                                            tooltip: t(
                                              'Superset with exercise above',
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: linkedPrev
                                                  ? palette.acc.withValues(
                                                      alpha: 0.16,
                                                    )
                                                  : Colors.transparent,
                                              foregroundColor: linkedPrev
                                                  ? palette.acc
                                                  : palette.muted,
                                              minimumSize: const Size(32, 28),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              ctx
                                                  .read<RoutineEditBloc>()
                                                  .add(RoutineLinkToggled(i));
                                            },
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            IconButton(
                                              icon: const AppIcon(
                                                'chevronUp',
                                                size: 13,
                                              ),
                                              tooltip: t('Move up'),
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(26, 24),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                              ),
                                              onPressed: isFirstUnit
                                                  ? null
                                                  : () {
                                                      ctx
                                                          .read<
                                                              RoutineEditBloc>()
                                                          .add(
                                                            RoutineUnitMoved(
                                                              i,
                                                              -1,
                                                            ),
                                                          );
                                                    },
                                            ),
                                            IconButton(
                                              icon: const AppIcon(
                                                'chevronDown',
                                                size: 13,
                                              ),
                                              tooltip: t('Move down'),
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(26, 24),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                              ),
                                              onPressed: isLastUnit
                                                  ? null
                                                  : () {
                                                      ctx
                                                          .read<
                                                              RoutineEditBloc>()
                                                          .add(
                                                            RoutineUnitMoved(
                                                              i,
                                                              1,
                                                            ),
                                                          );
                                                    },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: palette.muted,
        ),
      ),
    );
  }
}
