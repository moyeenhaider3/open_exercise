// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/number_field.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_entry_view.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';
import '../sheets/effort_picker_sheet.dart';
import 'set_sub_rows.dart';

/// Renders a single set row in an exercise block with steppers, effort picker, and done check.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 194-285, 432-475.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.entryIdx,
    required this.setIdx,
  });

  final int entryIdx;
  final int setIdx;

  void _openSetMenu(
    BuildContext context, {
    required WorkoutEntryView view,
    required SetEntry set,
    required int setsCount,
  }) {
    final bool warm = setIdx < view.isWarmup.length ? view.isWarmup[setIdx] : false;
    final bool isDrop = setIdx < view.isDrop.length ? view.isDrop[setIdx] : false;
    final bool isRestPause = setIdx < view.isRestPause.length ? view.isRestPause[setIdx] : false;
    final String title =
        setIdx < view.setMenuTitles.length ? view.setMenuTitles[setIdx] : (warm ? t('Warm-up') : t('Set {0}', <Object?>[setIdx + 1]));
    final String? subtitle = setIdx < view.setLabels.length ? view.setLabels[setIdx] : null;

    showMenuSheet(
      context,
      title: title,
      subtitle: subtitle,
      items: <MenuItemSpec>[
        if (!warm && view.mode == 'reps' && !isRestPause)
          MenuItemSpec(
            icon: 'arrowDown',
            label: t('Drop set'),
            sub: t('+ Drop'),
            onTap: () => context.read<WorkoutBloc>().add(WorkoutDropAdded(entryIdx, setIdx)),
          ),
        if (!warm && view.mode == 'reps' && !isDrop)
          MenuItemSpec(
            icon: 'bolt',
            label: t('Rest-pause burst'),
            sub: t('+ Burst'),
            onTap: () => context.read<WorkoutBloc>().add(WorkoutBurstAdded(entryIdx, setIdx)),
          ),
        MenuItemSpec(
          icon: 'trash',
          label: t('Remove this set'),
          danger: true,
          disabled: setsCount <= 1,
          onTap: () => context.read<WorkoutBloc>().add(WorkoutSetRemovedAt(entryIdx, setIdx)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocSelector<WorkoutBloc, WorkoutState, ({
      WorkoutEntryView view,
      SetEntry set,
      int setsCount,
      bool steppers,
    })?>(
      selector: (WorkoutState state) {
        if (state is! WorkoutRunning) return null;
        if (entryIdx < 0 || entryIdx >= state.active.entries!.length) return null;
        final WorkoutEntryView? view =
            entryIdx < state.entryViews.length ? state.entryViews[entryIdx] : null;
        final List<SetEntry>? sets = state.active.entries![entryIdx].sets;
        final SetEntry? set = (sets != null && setIdx < sets.length) ? sets[setIdx] : null;
        if (set == null || view == null) return null;

        return (
          view: view,
          set: set,
          setsCount: sets?.length ?? 1,
          steppers: state.wc.steppers,
        );
      },
      builder: (BuildContext context, ({
        WorkoutEntryView view,
        SetEntry set,
        int setsCount,
        bool steppers,
      })? data) {
        if (data == null) return const SizedBox.shrink();

        final WorkoutEntryView view = data.view;
        final SetEntry set = data.set;
        final int setsCount = data.setsCount;
        final bool steppers = data.steppers;

        final bool warm = setIdx < view.isWarmup.length ? view.isWarmup[setIdx] : false;
        final bool warmBefore = setIdx > 0 &&
            setIdx - 1 < view.isWarmup.length &&
            view.isWarmup[setIdx - 1];
        final bool isFirstWarmup = warm && !warmBefore;
        final bool isFirstWorkAfterWarmup = !warm && warmBefore;

        final int phaseNum =
            view.isWarmup.sublist(0, setIdx + 1).where((bool w) => w == warm).length;
        final bool isDone = set.done ?? false;

        final SetColumn col1 = view.col1;
        final SetColumn? col2 = view.col2;
        final SetColumn? col3 = view.col3;

        final int col1Flex = view.timed ? 10 : (col3 != null ? 14 : 14);
        final int col2Flex = view.timed ? 14 : (col3 != null ? 11 : 10);
        final int col3Flex = 7;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isFirstWarmup) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      t('Warm-up'),
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: palette.dim,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(child: Container(height: 1.0, color: palette.sep)),
                  ],
                ),
              ),
            ],
            if (isFirstWorkAfterWarmup)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                child: Container(height: 1.0, color: palette.sep),
              ),
            Opacity(
              opacity: isDone ? 0.45 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _openSetMenu(
                        context,
                        view: view,
                        set: set,
                        setsCount: setsCount,
                      ),
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? palette.acc : palette.surface2,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$phaseNum',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: isDone ? palette.onAcc : palette.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      flex: col1Flex,
                      child: _SetCell(
                        entryIdx: entryIdx,
                        setIdx: setIdx,
                        col: col1,
                        value: set.toJson()[col1.field] as num?,
                        steppers: steppers,
                      ),
                    ),
                    if (col2 != null) ...<Widget>[
                      const SizedBox(width: 6.0),
                      Expanded(
                        flex: col2Flex,
                        child: _SetCell(
                          entryIdx: entryIdx,
                          setIdx: setIdx,
                          col: col2,
                          value: set.toJson()[col2.field] as num?,
                          steppers: steppers,
                        ),
                      ),
                    ],
                    if (col3 != null) ...<Widget>[
                      const SizedBox(width: 6.0),
                      Expanded(
                        flex: col3Flex,
                        child: _EffortCell(
                          entryIdx: entryIdx,
                          setIdx: setIdx,
                          col: col3,
                          value: set.toJson()[col3.field] as num?,
                          effortColorToken:
                              setIdx < view.effortColors.length ? view.effortColors[setIdx] : null,
                          steppers: steppers,
                        ),
                      ),
                    ],
                    // D-02: Timed-set 'Start set' (setgo play) button is omitted until Phase 5 TMR-01;
                    // timed sets are logged by typing or stepping seconds.
                    const SizedBox(width: 8.0),
                    AppCheck(
                      checked: isDone,
                      onChanged: (_) => context.read<WorkoutBloc>().add(
                            WorkoutSetToggled(entryIdx, setIdx),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (!warm && view.mode == 'reps')
              SetSubRows(
                entryIdx: entryIdx,
                setIdx: setIdx,
              ),
          ],
        );
      },
    );
  }
}

class _SetCell extends StatelessWidget {
  const _SetCell({
    required this.entryIdx,
    required this.setIdx,
    required this.col,
    required this.value,
    required this.steppers,
  });

  final int entryIdx;
  final int setIdx;
  final SetColumn col;
  final num? value;
  final bool steppers;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      height: 40.0,
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: <Widget>[
          if (steppers)
            SizedBox(
              width: 28.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('minus', size: 12.0),
                padding: EdgeInsets.zero,
                color: palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(entryIdx, setIdx, col.field, -1, col.step),
                    ),
              ),
            ),
          Expanded(
            child: NumberField(
              value: value,
              decimal: col.decimal,
              nullable: col.optional,
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              onChanged: (num? v) => context.read<WorkoutBloc>().add(
                    WorkoutSetFieldChanged(entryIdx, setIdx, col.field, v),
                  ),
            ),
          ),
          if (steppers)
            SizedBox(
              width: 28.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('plus', size: 12.0),
                padding: EdgeInsets.zero,
                color: palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(entryIdx, setIdx, col.field, 1, col.step),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EffortCell extends StatelessWidget {
  const _EffortCell({
    required this.entryIdx,
    required this.setIdx,
    required this.col,
    required this.value,
    required this.effortColorToken,
    required this.steppers,
  });

  final int entryIdx;
  final int setIdx;
  final SetColumn col;
  final num? value;
  final String? effortColorToken;
  final bool steppers;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    void openPicker() {
      showEffortPickerSheet(
        context,
        kind: col.effortKind ?? 'rir',
        value: value,
        onPick: (num? nv) => context.read<WorkoutBloc>().add(
              WorkoutEffortPicked(entryIdx, setIdx, value: nv),
            ),
      );
    }

    if (value == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: openPicker,
        child: Container(
          height: 40.0,
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(10.0),
          ),
          alignment: Alignment.center,
          child: Text(
            col.header,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: palette.muted,
            ),
          ),
        ),
      );
    }

    final Color? color =
        effortColorToken != null ? palette.cssVar(effortColorToken!) : null;
    final Color bgColor = color != null
        ? Color.alphaBlend(color.withValues(alpha: 0.2), palette.surface2)
        : palette.surface2;
    final Border border = color != null
        ? Border.all(color: color, width: 1.5)
        : Border.all(color: Colors.transparent, width: 1.5);

    return Container(
      height: 40.0,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
        border: border,
      ),
      child: Row(
        children: <Widget>[
          if (steppers)
            SizedBox(
              width: 22.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('minus', size: 10.0),
                padding: EdgeInsets.zero,
                color: color ?? palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(entryIdx, setIdx, col.field, -1, col.step),
                    ),
              ),
            ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: openPicker,
              child: Center(
                child: Text(
                  fmtNum(value!),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          if (steppers)
            SizedBox(
              width: 22.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('plus', size: 10.0),
                padding: EdgeInsets.zero,
                color: color ?? palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(entryIdx, setIdx, col.field, 1, col.step),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
