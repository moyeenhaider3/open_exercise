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

/// Renders a unilateral (per-side) work set with L/R stacked rows.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 286-330, 440-460.
class SideRows extends StatelessWidget {
  const SideRows({
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
        setIdx < view.setMenuTitles.length ? view.setMenuTitles[setIdx] : t('Set {0}', <Object?>[setIdx + 1]);
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
      bool warmBefore,
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

        final bool warmBefore = setIdx > 0 &&
            setIdx - 1 < view.isWarmup.length &&
            view.isWarmup[setIdx - 1];

        return (
          view: view,
          set: set,
          setsCount: sets?.length ?? 1,
          warmBefore: warmBefore,
          steppers: state.wc.steppers,
        );
      },
      builder: (BuildContext context, ({
        WorkoutEntryView view,
        SetEntry set,
        int setsCount,
        bool warmBefore,
        bool steppers,
      })? data) {
        if (data == null) return const SizedBox.shrink();

        final WorkoutEntryView view = data.view;
        final SetEntry set = data.set;
        final int setsCount = data.setsCount;
        final bool warmBefore = data.warmBefore;
        final bool steppers = data.steppers;

        final bool isDone = set.done ?? false;
        final int phaseNum =
            view.isWarmup.sublist(0, setIdx + 1).where((bool w) => !w).length;

        final SetEntry leftSide = set.sides?.left ?? const SetEntry();
        final SetEntry rightSide = set.sides?.right ?? const SetEntry();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (warmBefore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                child: Container(height: 1.0, color: palette.sep),
              ),
            Opacity(
              opacity: isDone ? 0.45 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _SideRow(
                            entryIdx: entryIdx,
                            setIdx: setIdx,
                            side: 'L',
                            sideSet: leftSide,
                            view: view,
                            steppers: steppers,
                          ),
                          SetSubRows(
                            entryIdx: entryIdx,
                            setIdx: setIdx,
                            side: 'L',
                          ),
                          const SizedBox(height: 4.0),
                          _SideRow(
                            entryIdx: entryIdx,
                            setIdx: setIdx,
                            side: 'R',
                            sideSet: rightSide,
                            view: view,
                            steppers: steppers,
                          ),
                          SetSubRows(
                            entryIdx: entryIdx,
                            setIdx: setIdx,
                            side: 'R',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({
    required this.entryIdx,
    required this.setIdx,
    required this.side,
    required this.sideSet,
    required this.view,
    required this.steppers,
  });

  final int entryIdx;
  final int setIdx;
  final String side;
  final SetEntry sideSet;
  final WorkoutEntryView view;
  final bool steppers;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool sideDone = sideSet.done ?? false;

    final SetColumn col1 = view.col1;
    final SetColumn? col2 = view.col2;
    final SetColumn? col3 = view.col3;

    final int col1Flex = col3 != null ? 14 : 14;
    final int col2Flex = col3 != null ? 14 : 10;
    final int col3Flex = 7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: sideDone ? palette.acc : palette.surface2,
            ),
            alignment: Alignment.center,
            child: Text(
              side,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: sideDone ? palette.onAcc : palette.dim,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Expanded(
            flex: col1Flex,
            child: _SideCell(
              entryIdx: entryIdx,
              setIdx: setIdx,
              side: side,
              col: col1,
              value: sideSet.toJson()[col1.field] as num?,
              steppers: steppers,
            ),
          ),
          if (col2 != null) ...<Widget>[
            const SizedBox(width: 6.0),
            Expanded(
              flex: col2Flex,
              child: _SideCell(
                entryIdx: entryIdx,
                setIdx: setIdx,
                side: side,
                col: col2,
                value: sideSet.toJson()[col2.field] as num?,
                steppers: steppers,
              ),
            ),
          ],
          if (col3 != null) ...<Widget>[
            const SizedBox(width: 6.0),
            Expanded(
              flex: col3Flex,
              child: _SideEffortCell(
                entryIdx: entryIdx,
                setIdx: setIdx,
                side: side,
                col: col3,
                value: sideSet.toJson()[col3.field] as num?,
                effortColorToken:
                    setIdx < view.effortColors.length ? view.effortColors[setIdx] : null,
                steppers: steppers,
              ),
            ),
          ],
          const SizedBox(width: 8.0),
          AppCheck(
            checked: sideDone,
            onChanged: (_) => context.read<WorkoutBloc>().add(
                  WorkoutSetToggled(entryIdx, setIdx, side: side),
                ),
          ),
        ],
      ),
    );
  }
}

class _SideCell extends StatelessWidget {
  const _SideCell({
    required this.entryIdx,
    required this.setIdx,
    required this.side,
    required this.col,
    required this.value,
    required this.steppers,
  });

  final int entryIdx;
  final int setIdx;
  final String side;
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
              width: 24.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('minus', size: 12.0),
                padding: EdgeInsets.zero,
                color: palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(
                        entryIdx,
                        setIdx,
                        col.field,
                        -1,
                        col.step,
                        side: side,
                      ),
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
                    WorkoutSideFieldChanged(entryIdx, setIdx, side, col.field, v),
                  ),
            ),
          ),
          if (steppers)
            SizedBox(
              width: 24.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('plus', size: 12.0),
                padding: EdgeInsets.zero,
                color: palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(
                        entryIdx,
                        setIdx,
                        col.field,
                        1,
                        col.step,
                        side: side,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideEffortCell extends StatelessWidget {
  const _SideEffortCell({
    required this.entryIdx,
    required this.setIdx,
    required this.side,
    required this.col,
    required this.value,
    required this.effortColorToken,
    required this.steppers,
  });

  final int entryIdx;
  final int setIdx;
  final String side;
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
              WorkoutEffortPicked(
                entryIdx,
                setIdx,
                side: side,
                value: nv,
              ),
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
              width: 20.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('minus', size: 10.0),
                padding: EdgeInsets.zero,
                color: color ?? palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(
                        entryIdx,
                        setIdx,
                        col.field,
                        -1,
                        col.step,
                        side: side,
                      ),
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
              width: 20.0,
              height: 40.0,
              child: IconButton(
                icon: const AppIcon('plus', size: 10.0),
                padding: EdgeInsets.zero,
                color: color ?? palette.muted,
                onPressed: () => context.read<WorkoutBloc>().add(
                      WorkoutSetFieldBumped(
                        entryIdx,
                        setIdx,
                        col.field,
                        1,
                        col.step,
                        side: side,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
