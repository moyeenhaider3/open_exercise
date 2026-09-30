// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/body_map/body_map.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/chips.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';
import '../../library/view/exercise_media.dart';
import '../bloc/muscles_bloc.dart';
import '../bloc/muscles_event.dart';
import '../bloc/muscles_state.dart';

/// Reusable Muscle Explorer widget displaying body map, muscle selection chips,
/// filters, and exercise results.
///
/// Ports `../openGym/frontend/src/components/MuscleExplorer.jsx`.
class MuscleExplorer extends StatelessWidget {
  const MuscleExplorer({
    super.key,
    this.onPick,
    this.onDetail,
    this.onPlan,
  });

  final void Function(ExerciseDef ex)? onPick;
  final void Function(ExerciseDef ex)? onDetail;
  final void Function(ExerciseDef ex)? onPlan;

  void _choose(ExerciseDef e) {
    if (onPick != null) {
      onPick!(e);
    } else {
      onDetail?.call(e);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();

    return BlocBuilder<MusclesBloc, MusclesState>(
      builder: (BuildContext context, MusclesState rawState) {
        if (rawState is! MusclesReady) {
          return const SizedBox.shrink();
        }

        final MusclesReady state = rawState;
        final MusclesBloc bloc = context.read<MusclesBloc>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Equipment profile indicator row
            if (state.profile != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
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
                      onTap: () => bloc.add(const MusclesShowAllToggled()),
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

            // Body map card & muscle chips
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BodyMap(
                    body: state.body,
                    selected: state.selected,
                    onMuscle: (String slug) =>
                        bloc.add(MusclesMuscleTapped(slug)),
                  ),
                  const SizedBox(height: 10.0),
                  ChipStrip<String>(
                    selected: state.selected ?? '',
                    onSelected: (String slug) =>
                        bloc.add(MusclesMuscleTapped(slug)),
                    items: <ChipItem<String>>[
                      for (final String m in state.muscleOrder)
                        ChipItem<String>(
                          value: m,
                          label: state.muscleNames[m] ?? m,
                          trailing: '${state.counts[m] ?? 0}',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Empty state when picking without selection
            if (state.selected == null && onPick != null) ...<Widget>[
              const SizedBox(height: 24.0),
              EmptyState(
                icon: 'target',
                text: t('Choose a muscle to see exercises that train it.'),
              ),
            ],

            // Selected muscle exercises list & filters
            if (state.selected != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 16.0, 14.0, 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: SectionHeader(
                        t('Exercises for {0}', <Object?>[
                          state.muscleNames[state.selected] ?? state.selected,
                        ]),
                      ),
                    ),
                    AppButton(
                      label: Text(t('Clear selection')),
                      variant: AppButtonVariant.ghost,
                      small: true,
                      onPressed: () =>
                          bloc.add(MusclesMuscleTapped(state.selected!)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: SearchField(
                  value: state.q,
                  placeholder: t('Search…'),
                  onChanged: (String q) => bloc.add(MusclesQueryChanged(q)),
                ),
              ),
              const SizedBox(height: 8.0),
              ChipStrip<String>(
                noCap: true,
                selected: state.bp,
                onSelected: (String bp) =>
                    bloc.add(MusclesBodyPartSelected(bp)),
                items: <ChipItem<String>>[
                  ChipItem<String>(value: '', label: t('All')),
                  for (final String bp in catalogue.bodyParts)
                    ChipItem<String>(value: bp, label: t(bp)),
                ],
              ),
              if (state.eqOpts.length > 1)
                ChipStrip<String>(
                  selected: state.eq,
                  onSelected: (String eq) =>
                      bloc.add(MusclesEquipmentSelected(eq)),
                  items: <ChipItem<String>>[
                    ChipItem<String>(value: '', label: t('Any equipment')),
                    for (final String eq in state.eqOpts)
                      ChipItem<String>(value: eq, label: t(eq)),
                  ],
                ),
              const SizedBox(height: 8.0),
              if (state.results.isEmpty)
                EmptyState(
                  icon: 'magnifier',
                  text: t('No match'),
                )
              else ...<Widget>[
                for (int i = 0;
                    i <
                        (state.shown < state.results.length
                            ? state.shown
                            : state.results.length);
                    i++)
                  _buildExerciseRow(
                    context,
                    state.results[i],
                    state,
                    palette,
                    catalogue,
                  ),
                if (state.results.length > state.shown)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppButton(
                      label: Text(t('Show more')),
                      onPressed: () =>
                          bloc.add(const MusclesShowMoreRequested()),
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildExerciseRow(
    BuildContext context,
    ExerciseDef e,
    MusclesReady state,
    AppPalette palette,
    ExerciseCatalogue catalogue,
  ) {
    final double best = state.bestWeights[e.id] ?? 0.0;
    final bool fav = state.favIds.contains(e.id);
    final String muscleKey = catalogue.muscleName[e.tg] ?? e.tg ?? e.bp;
    final String targetLabel =
        t(state.primaryIds.contains(e.id) ? 'Primary target' : 'Also trains');
    final String subtitleText = '$targetLabel · ${t(muscleKey)} · ${t(e.eq)}';

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
        subtitleText,
        style: TextStyle(fontSize: 13.0, color: palette.muted),
      ),
      trailing: onPick != null
          ? const AppIcon('plus', size: 18.0)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (best > 0) ...<Widget>[
                  AppTag(
                    label: fmtNum(best),
                    isAccent: true,
                  ),
                  const SizedBox(width: 8.0),
                ],
                if (onPlan != null)
                  AppButton(
                    label: Text(t('Plan')),
                    variant: AppButtonVariant.tinted,
                    small: true,
                    icon: 'plus',
                    onPressed: () => onPlan!(e),
                  ),
              ],
            ),
      onTap: () => _choose(e),
    );
  }
}
