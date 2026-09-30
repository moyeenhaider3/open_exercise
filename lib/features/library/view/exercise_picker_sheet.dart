// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/chips.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/rows.dart';
import '../../muscles/bloc/muscles_bloc.dart';
import '../../muscles/view/muscle_explorer.dart';
import '../bloc/exercise_picker_cubit.dart';
import 'custom_exercise_sheet.dart';
import 'exercise_media.dart';

/// Handle returned by [showExercisePickerSheet] allowing callers to programmatically dismiss the sheet.
class PickerHandle {
  PickerHandle();
  BuildContext? _context;
  bool _closed = false;

  /// Closes the exercise picker modal.
  void close() {
    if (!_closed && _context != null && _context!.mounted) {
      _closed = true;
      Navigator.of(_context!).pop();
    }
  }
}

/// Opens the exercise picker bottom sheet.
/// Ported from ../openGym/frontend/src/sheets.jsx:907-1004 ExercisePicker.
PickerHandle showExercisePickerSheet(
  BuildContext context, {
  required void Function(ExerciseDef ex, bool quick, PickerHandle picker) onPick,
}) {
  final PickerHandle handle = PickerHandle();

  showAppSheet<void>(
    context,
    (BuildContext ctx) {
      handle._context = ctx;
      return BlocProvider<ExercisePickerCubit>(
        create: (BuildContext c) => ExercisePickerCubit(
          gymState: c.read<GymStateCubit>(),
          catalogue: c.read<ExerciseCatalogue>(),
        ),
        child: _ExercisePickerSheet(
          handle: handle,
          onPick: onPick,
        ),
      );
    },
  );

  return handle;
}

class _ExercisePickerSheet extends StatelessWidget {
  const _ExercisePickerSheet({
    required this.handle,
    required this.onPick,
  });

  final PickerHandle handle;
  final void Function(ExerciseDef ex, bool quick, PickerHandle picker) onPick;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final ExercisePickerCubit cubit = context.read<ExercisePickerCubit>();

    return BlocBuilder<ExercisePickerCubit, ExercisePickerState>(
      builder: (BuildContext context, ExercisePickerState state) {
        // Build body part chip options
        final List<ChipItem<String>> bpChips = <ChipItem<String>>[
          ChipItem<String>(value: '', label: t('All')),
          if (state.usageMap.isNotEmpty)
            const ChipItem<String>(value: '★', label: '★'),
          if (state.favCount > 0)
            const ChipItem<String>(value: '☆', label: '☆'),
          for (final String bp in catalogue.bodyParts)
            ChipItem<String>(value: bp, label: capWords(bp)),
        ];

        // Build equipment chip options
        final List<ChipItem<String>> eqChips = <ChipItem<String>>[
          ChipItem<String>(value: '', label: t('All')),
          for (final String eq in state.equipmentOptions)
            ChipItem<String>(value: eq, label: capWords(eq)),
        ];

        final int displayedCount = min(state.results.length, state.shown);
        final bool hasMore = state.results.length > state.shown;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Title and mode toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      t('Add exercise'),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.byMuscle)
                      AppButton(
                        label: Text(t('All')),
                        variant: AppButtonVariant.ghost,
                        small: true,
                        onPressed: () => cubit.byMuscleChanged(false),
                      )
                    else
                      AppButton(
                        label: Text(t('By muscle')),
                        variant: AppButtonVariant.tinted,
                        small: true,
                        icon: 'target',
                        onPressed: () => cubit.byMuscleChanged(true),
                      ),
                  ],
                ),
              ),

              if (state.byMuscle)
                Flexible(
                  child: SingleChildScrollView(
                    child: BlocProvider<MusclesBloc>(
                      create: (BuildContext c) => MusclesBloc(
                        gymState: c.read<GymStateCubit>(),
                        catalogue: c.read<ExerciseCatalogue>(),
                        engine: c.read<JsEngineService>(),
                      ),
                      child: MuscleExplorer(
                        onPick: (ExerciseDef ex) => onPick(ex, false, handle),
                      ),
                    ),
                  ),
                )
              else ...<Widget>[
                // Search bar
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: SearchField(
                  value: state.q,
                  placeholder: t('Search exercises...'),
                  onChanged: cubit.queryChanged,
                ),
              ),
              const SizedBox(height: 8.0),

              // Body parts strip
              ChipStrip<String>(
                items: bpChips,
                selected: state.bp,
                onSelected: cubit.bodyPartSelected,
              ),

              // Equipment strip (if options exist)
              if (state.equipmentOptions.isNotEmpty)
                ChipStrip<String>(
                  items: eqChips,
                  selected: state.eq,
                  onSelected: cubit.equipmentSelected,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                ),
              const SizedBox(height: 6.0),

              // Create your own exercise row
              ListItem(
                leading: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: palette.acc.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: AppIcon('plus', size: 20.0, color: palette.acc),
                  ),
                ),
                title: Text(
                  t('Create your own exercise'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.acc,
                  ),
                ),
                onTap: () {
                  showCustomExerciseSheet(
                    context,
                    prefill: state.q,
                    onDone: (ExerciseDef saved) {
                      onPick(saved, false, handle);
                    },
                  );
                },
              ),
              const Divider(height: 1.0),

              // Results list or EmptyState
              Expanded(
                child: state.results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: EmptyState(
                            text: t('No exercises found'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedCount + (hasMore ? 1 : 0),
                        itemBuilder: (BuildContext ctx, int index) {
                          if (index == displayedCount) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AppButton(
                                label: Text(t('Show more')),
                                variant: AppButtonVariant.ghost,
                                onPressed: cubit.showMore,
                              ),
                            );
                          }

                          final ExerciseDef ex = state.results[index];
                          final bool isUsed = state.usageMap.containsKey(ex.id);

                          return ListItem(
                            leading: ExerciseThumb(ex: ex, size: 40.0),
                            title: Text(capWords(ex.n)),
                            subtitle: Text(
                              '${capWords(ex.eq)} · ${capWords(ex.tg ?? ex.bp)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (isUsed) ...<Widget>[
                                  const AppTag(label: '★'),
                                  const SizedBox(width: 4.0),
                                ],
                                InkWell(
                                  onTap: () => onPick(ex, true, handle),
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: AppIcon('plus', size: 18.0, color: palette.acc),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => onPick(ex, false, handle),
                          );
                        },
                      ),
              ),
            ],
          ],
          ),
        );
      },
    );
  }
}
