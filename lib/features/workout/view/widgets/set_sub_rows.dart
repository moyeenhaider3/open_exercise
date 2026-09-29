// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/number_field.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_entry_view.dart';
import '../../bloc/workout_event.dart';
import '../../bloc/workout_state.dart';

/// Renders drop-set and rest-pause sub-rows plus shortcut chips for a set.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 330-365, 465-485.
class SetSubRows extends StatelessWidget {
  const SetSubRows({
    super.key,
    required this.entryIdx,
    required this.setIdx,
    this.side,
  });

  final int entryIdx;
  final int setIdx;
  final String? side;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocSelector<WorkoutBloc, WorkoutState, ({
      List<DropEntry> drops,
      List<ClusterEntry> bursts,
      num loadStep,
      bool isDrop,
      bool isRestPause,
      bool setShortcuts,
    })?>(
      selector: (WorkoutState state) {
        if (state is! WorkoutRunning) return null;
        if (entryIdx < 0 || entryIdx >= state.active.entries!.length) return null;
        final WorkoutEntryView? view =
            entryIdx < state.entryViews.length ? state.entryViews[entryIdx] : null;
        final SetEntry? set =
            setIdx < (state.active.entries![entryIdx].sets?.length ?? 0)
                ? state.active.entries![entryIdx].sets![setIdx]
                : null;
        if (set == null || view == null) return null;

        final SetEntry targetSet;
        if (side == 'L') {
          targetSet = set.sides?.left ?? const SetEntry();
        } else if (side == 'R') {
          targetSet = set.sides?.right ?? const SetEntry();
        } else {
          targetSet = set;
        }

        final num loadStep = view.col1.field == 'w' ? view.col1.step : (view.col2?.step ?? 2.5);
        final bool isDrop = setIdx < view.isDrop.length ? view.isDrop[setIdx] : false;
        final bool isRestPause = setIdx < view.isRestPause.length ? view.isRestPause[setIdx] : false;

        return (
          drops: targetSet.drops ?? const <DropEntry>[],
          bursts: targetSet.clusters ?? const <ClusterEntry>[],
          loadStep: loadStep,
          isDrop: isDrop,
          isRestPause: isRestPause,
          setShortcuts: state.wc.setShortcuts,
        );
      },
      builder: (BuildContext context, ({
        List<DropEntry> drops,
        List<ClusterEntry> bursts,
        num loadStep,
        bool isDrop,
        bool isRestPause,
        bool setShortcuts,
      })? data) {
        if (data == null) return const SizedBox.shrink();

        final List<DropEntry> drops = data.drops;
        final List<ClusterEntry> bursts = data.bursts;
        final num loadStep = data.loadStep;
        final bool isDrop = data.isDrop;
        final bool isRestPause = data.isRestPause;
        final bool setShortcuts = data.setShortcuts;

        final bool hasItems = drops.isNotEmpty || bursts.isNotEmpty;
        if (!hasItems && (side != null || !setShortcuts)) {
          return const SizedBox.shrink();
        }

        final double leftPadding = side != null ? 0.0 : 32.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int di = 0; di < drops.length; di++) ...<Widget>[
              Padding(
                padding: EdgeInsets.only(left: leftPadding, top: 3.0, bottom: 3.0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 48.0,
                      child: Text(
                        t('Drop {0}', <Object?>[di + 1]),
                        style: TextStyle(fontSize: 11.0, color: palette.dim),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      flex: 1,
                      child: _MiniStepper(
                        value: drops[di].w,
                        decimal: true,
                        onDecrement: () => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldBumped(
                                entryIdx,
                                setIdx,
                                di,
                                'w',
                                -1,
                                loadStep,
                                side: side,
                              ),
                            ),
                        onIncrement: () => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldBumped(
                                entryIdx,
                                setIdx,
                                di,
                                'w',
                                1,
                                loadStep,
                                side: side,
                              ),
                            ),
                        onChanged: (num? v) => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldChanged(
                                entryIdx,
                                setIdx,
                                di,
                                'w',
                                v,
                                side: side,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      flex: 1,
                      child: _MiniStepper(
                        value: drops[di].r,
                        decimal: false,
                        onDecrement: () => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldBumped(
                                entryIdx,
                                setIdx,
                                di,
                                'r',
                                -1,
                                1,
                                side: side,
                              ),
                            ),
                        onIncrement: () => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldBumped(
                                entryIdx,
                                setIdx,
                                di,
                                'r',
                                1,
                                1,
                                side: side,
                              ),
                            ),
                        onChanged: (num? v) => context.read<WorkoutBloc>().add(
                              WorkoutDropFieldChanged(
                                entryIdx,
                                setIdx,
                                di,
                                'r',
                                v,
                                side: side,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    SizedBox(
                      width: 26.0,
                      height: 26.0,
                      child: IconButton(
                        icon: const AppIcon('xmark', size: 12.0),
                        padding: EdgeInsets.zero,
                        color: palette.muted,
                        tooltip: t('Remove drop'),
                        onPressed: () => context.read<WorkoutBloc>().add(
                              WorkoutDropRemoved(entryIdx, setIdx, di),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (int ci = 0; ci < bursts.length; ci++) ...<Widget>[
              Padding(
                padding: EdgeInsets.only(left: leftPadding, top: 3.0, bottom: 3.0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 48.0,
                      child: Text(
                        t('Burst {0}', <Object?>[ci + 1]),
                        style: TextStyle(fontSize: 11.0, color: palette.dim),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      flex: 1,
                      child: _MiniStepper(
                        value: bursts[ci].r,
                        decimal: false,
                        onDecrement: () => context.read<WorkoutBloc>().add(
                              WorkoutBurstFieldBumped(
                                entryIdx,
                                setIdx,
                                ci,
                                -1,
                                side: side,
                              ),
                            ),
                        onIncrement: () => context.read<WorkoutBloc>().add(
                              WorkoutBurstFieldBumped(
                                entryIdx,
                                setIdx,
                                ci,
                                1,
                                side: side,
                              ),
                            ),
                        onChanged: (num? v) => context.read<WorkoutBloc>().add(
                              WorkoutBurstFieldChanged(
                                entryIdx,
                                setIdx,
                                ci,
                                v,
                                side: side,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '${bursts[ci].restSec ?? 0}s',
                      style: TextStyle(fontSize: 12.0, color: palette.dim),
                    ),
                    const SizedBox(width: 6.0),
                    SizedBox(
                      width: 26.0,
                      height: 26.0,
                      child: IconButton(
                        icon: const AppIcon('xmark', size: 12.0),
                        padding: EdgeInsets.zero,
                        color: palette.muted,
                        tooltip: t('Remove burst'),
                        onPressed: () => context.read<WorkoutBloc>().add(
                              WorkoutBurstRemoved(entryIdx, setIdx, ci),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (side == null && setShortcuts) ...<Widget>[
              const SizedBox(height: 4.0),
              Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 6.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: <Widget>[
                    if (!isRestPause)
                      InkWell(
                        borderRadius: BorderRadius.circular(8.0),
                        onTap: () => context.read<WorkoutBloc>().add(
                              WorkoutDropAdded(entryIdx, setIdx),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AppIcon('arrowDown', size: 12.0, color: palette.acc),
                              const SizedBox(width: 4.0),
                              Text(
                                '+ Drop',
                                style: TextStyle(
                                  color: palette.acc,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!isDrop)
                      InkWell(
                        borderRadius: BorderRadius.circular(8.0),
                        onTap: () => context.read<WorkoutBloc>().add(
                              WorkoutBurstAdded(entryIdx, setIdx),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AppIcon('bolt', size: 12.0, color: palette.acc),
                              const SizedBox(width: 4.0),
                              Text(
                                '+ Burst',
                                style: TextStyle(
                                  color: palette.acc,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.value,
    required this.decimal,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  final num? value;
  final bool decimal;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<num?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26.0,
            height: 32.0,
            child: IconButton(
              icon: const AppIcon('minus', size: 10.0),
              padding: EdgeInsets.zero,
              color: palette.muted,
              onPressed: onDecrement,
            ),
          ),
          Expanded(
            child: NumberField(
              value: value,
              decimal: decimal,
              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 26.0,
            height: 32.0,
            child: IconButton(
              icon: const AppIcon('plus', size: 10.0),
              padding: EdgeInsets.zero,
              color: palette.muted,
              onPressed: onIncrement,
            ),
          ),
        ],
      ),
    );
  }
}
