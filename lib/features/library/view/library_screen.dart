// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/chips.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';
import '../../../core/ui_kit/toast.dart';
import '../../plan/view/sheets/add_to_routine_sheet.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_state.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import 'custom_exercise_sheet.dart';
import 'exercise_detail_sheet.dart';
import 'exercise_media.dart';

/// Exercise library browsing and search screen.
/// Ports `../openGym/frontend/src/views/Library.jsx`.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LibraryBloc>(
      create: (BuildContext ctx) => LibraryBloc(
        gymState: ctx.read<GymStateCubit>(),
        catalogue: ctx.read<ExerciseCatalogue>(),
        engine: ctx.read<JsEngineService>(),
      ),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final AppPalette palette = AppPalette.of(context);

    return BlocListener<ExercisesBloc, ExercisesState>(
      listenWhen: (ExercisesState prev, ExercisesState curr) =>
          curr.signal != null && curr.signal != prev.signal,
      listener: (BuildContext ctx, ExercisesState state) {
        final ExercisesSignal? sig = state.signal;
        if (sig is ExercisesSignalToast) {
          showToast(ctx, sig.message);
        } else if (sig is ExercisesSignalAddedToRoutine) {
          showToast(ctx, sig.message);
          if (sig.routineId != null && sig.routineId!.isNotEmpty) {
            ctx.go(AppRoutes.routinePath(sig.routineId!));
          }
        }
      },
      child: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (BuildContext ctx, LibraryState state) {
          final List<ExerciseDef> results = state.results;
          final int count = math.min(state.shown, results.length);

          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ScreenHeader(
                      title: t('Exercises'),
                      subtitle: t(
                        '{0} exercises with animations',
                        <Object?>[state.total],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14.0, 0.0, 14.0, 10.0),
                      child: SearchField(
                        value: state.query,
                        placeholder: t('Search…'),
                        onChanged: (String q) {
                          ctx.read<LibraryBloc>().add(LibraryQueryChanged(q));
                        },
                      ),
                    ),
                    if (state.profile != null) ...<Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
                        child: Row(
                          children: <Widget>[
                            AppIcon(
                              'dumbbell',
                              size: 13.0,
                              color: palette.muted,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                state.showAll
                                    ? t('Showing all equipment')
                                    : t(
                                        'Showing what you have in "{0}"',
                                        <Object?>[state.profile!.name],
                                      ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ctx
                                    .read<LibraryBloc>()
                                    .add(const LibraryShowAllToggled());
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surface2,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  state.showAll
                                      ? t(
                                          'Filter by "{0}"',
                                          <Object?>[state.profile!.name],
                                        )
                                      : t('Show all equipment'),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: palette.acc,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ChipStrip<String>(
                      items: <ChipItem<String>>[
                        ChipItem<String>(value: '', label: t('All')),
                        ...catalogue.bodyParts.map(
                          (String b) =>
                              ChipItem<String>(value: b, label: t(b)),
                        ),
                      ],
                      selected: state.bodyPart,
                      noCap: true,
                      onSelected: (String bp) {
                        ctx.read<LibraryBloc>().add(LibraryBodyPartSelected(bp));
                      },
                    ),
                    if (state.eqOptions.length > 1) ...<Widget>[
                      const SizedBox(height: 4.0),
                      ChipStrip<String>(
                        items: <ChipItem<String>>[
                          ChipItem<String>(
                            value: '',
                            label: t('Any equipment'),
                          ),
                          ...state.eqOptions.map(
                            (String eq) =>
                                ChipItem<String>(value: eq, label: t(eq)),
                          ),
                        ],
                        selected: state.eqOn,
                        noCap: true,
                        onSelected: (String eq) {
                          ctx
                              .read<LibraryBloc>()
                              .add(LibraryEquipmentSelected(eq));
                        },
                      ),
                    ],
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
              if (results.isEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      ListItem(
                        leading: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: AppIcon(
                              'sparkles',
                              size: 18.0,
                              color: palette.acc,
                            ),
                          ),
                        ),
                        title: Text(t('Create your own exercise')),
                        subtitle: Text(t('name + body part, no animation')),
                        trailing: const AppIcon('plus', size: 18.0),
                        onTap: () {
                          showCustomExerciseSheet(
                            ctx,
                            prefill: state.query.trim(),
                            onDone: (ExerciseDef created) {
                              showExerciseDetailSheet(ctx, created);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 32.0),
                      EmptyState(
                        icon: 'magnifier',
                        text: t('No match'),
                      ),
                    ],
                  ),
                )
              else
                SliverList.builder(
                  itemCount: 1 + count,
                  itemBuilder: (BuildContext rowCtx, int index) {
                    if (index == 0) {
                      return ListItem(
                        leading: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: AppIcon(
                              'sparkles',
                              size: 18.0,
                              color: palette.acc,
                            ),
                          ),
                        ),
                        title: Text(t('Create your own exercise')),
                        subtitle: Text(t('name + body part, no animation')),
                        trailing: const AppIcon('plus', size: 18.0),
                        onTap: () {
                          showCustomExerciseSheet(
                            ctx,
                            prefill: state.query.trim(),
                            onDone: (ExerciseDef created) {
                              showExerciseDetailSheet(ctx, created);
                            },
                          );
                        },
                      );
                    }

                    final ExerciseDef e = results[index - 1];
                    final double best = state.bestWeights[e.id] ?? 0.0;
                    final bool fav = state.favIds.contains(e.id);
                    final String muscleKey =
                        catalogue.muscleName[e.tg] ?? e.tg ?? e.bp;

                    return ListItem(
                      leading: ExerciseThumb(ex: e),
                      title: Row(
                        children: <Widget>[
                          if (fav) ...<Widget>[
                            AppIcon(
                              'starFill',
                              size: 14.0,
                              color: palette.yellow,
                            ),
                            const SizedBox(width: 4.0),
                          ],
                          Expanded(
                            child: Text(
                              _capitalize(catalogue.exerciseNameFor(e)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${t(muscleKey)} · ${t(e.eq)}',
                        style: TextStyle(fontSize: 13.0, color: palette.muted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (best > 0) ...<Widget>[
                            AppTag(
                              label: fmtNum(best),
                              isAccent: true,
                            ),
                            const SizedBox(width: 8.0),
                          ],
                          AppButton(
                            label: Text(t('Plan')),
                            variant: AppButtonVariant.tinted,
                            small: true,
                            icon: 'plus',
                            onPressed: () => showAddToRoutineSheet(ctx, e),
                          ),
                        ],
                      ),
                      onTap: () => showExerciseDetailSheet(ctx, e),
                    );
                  },
                ),
              if (results.length > state.shown)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppButton(
                      label: Text(t('Show more')),
                      onPressed: () {
                        ctx
                            .read<LibraryBloc>()
                            .add(const LibraryShowMoreRequested());
                      },
                    ),
                  ),
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
