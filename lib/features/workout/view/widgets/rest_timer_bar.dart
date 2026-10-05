// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of components/RestTimer.jsx.
///
/// Floating bar that surfaces the rest or work countdown above the tab bar.
/// Idle state renders nothing ([SizedBox.shrink]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../bloc/workout_timer_bloc.dart';
import '../../bloc/workout_timer_event.dart';
import '../../bloc/workout_timer_state.dart';

/// Floating timer bar: rest variant (column) or work variant (row).
/// Ports RestTimer.jsx layout and ../openGym/frontend/src/index.css lines 1021-1055.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({super.key});

  /// Formats seconds as m:ss (tabular-figures style).
  static String _clock(int sec) {
    final int s = sec < 0 ? 0 : sec;
    final int minutes = s ~/ 60;
    final int seconds = s % 60;
    final String pad = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$pad';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutTimerBloc, WorkoutTimerState>(
      builder: (BuildContext ctx, WorkoutTimerState state) {
        return switch (state) {
          WorkoutTimerIdle() => const SizedBox.shrink(),
          WorkoutRestRunning(:final int left, :final int total, :final int endsAtMs) =>
            _RestBar(left: left, total: total, endsAtMs: endsAtMs),
          WorkoutWorkRunning(
            :final int left,
            :final int total,
            :final String label,
          ) =>
            _WorkBar(left: left, total: total, label: label),
        };
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Rest variant: column — head row (clock + bar) + actions row
// ---------------------------------------------------------------------------

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.left,
    required this.total,
    required this.endsAtMs,
  });

  final int left;
  final int total;
  final int endsAtMs;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double progress = total > 0 ? (left / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Head row: clock + animated progress bar
        Row(
          children: <Widget>[
            const SizedBox(width: 12.0),
            Text(
              RestTimerBar._clock(left),
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                fontVariations: <FontVariation>[],
                letterSpacing: 0.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _TimerTrack(progress: progress, palette: palette),
            ),
            const SizedBox(width: 12.0),
          ],
        ),
        const SizedBox(height: 4.0),
        // Actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: <Widget>[
              // -15s button
              Semantics(
                label: t('Subtract 15 seconds'),
                child: AppButton(
                  label: Text(t('-15s')),
                  small: true,
                  icon: 'minus',
                  onPressed: () =>
                      context.read<WorkoutTimerBloc>().add(const WorkoutRestAdded(-15)),
                ),
              ),
              const SizedBox(width: 8.0),
              // +15s button
              Semantics(
                label: t('Add 15 seconds'),
                child: AppButton(
                  label: Text(t('+15s')),
                  small: true,
                  icon: 'plus',
                  onPressed: () =>
                      context.read<WorkoutTimerBloc>().add(const WorkoutRestAdded(15)),
                ),
              ),
              const Spacer(),
              // Skip (primary, min-width 84)
              SizedBox(
                width: 84.0,
                child: AppButton(
                  label: Text(t('Skip')),
                  variant: AppButtonVariant.primary,
                  small: true,
                  onPressed: () =>
                      context.read<WorkoutTimerBloc>().add(const WorkoutRestStopped()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Work variant: one row with accent hairline border
// ---------------------------------------------------------------------------

class _WorkBar extends StatelessWidget {
  const _WorkBar({
    required this.left,
    required this.total,
    required this.label,
  });

  final int left;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double progress = total > 0 ? (left / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.acc, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: <Widget>[
          // Clock in accent
          Text(
            RestTimerBar._clock(left),
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: palette.acc,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8.0),
          // Grow column: label + bar
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (label.isNotEmpty) ...<Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                ],
                _TimerTrack(progress: progress, palette: palette),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Cancel
          AppButton(
            label: Text(t('Cancel')),
            small: true,
            onPressed: () =>
                context.read<WorkoutTimerBloc>().add(const WorkoutWorkStopped()),
          ),
          const SizedBox(width: 8.0),
          // Done (primary, check icon)
          AppButton(
            label: Text(t('Done')),
            variant: AppButtonVariant.primary,
            small: true,
            icon: 'check',
            onPressed: () =>
                context.read<WorkoutTimerBloc>().add(const WorkoutWorkFinishedEarly()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared animated progress track
// ---------------------------------------------------------------------------

class _TimerTrack extends StatelessWidget {
  const _TimerTrack({required this.progress, required this.palette});

  final double progress;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.0),
        child: Stack(
          children: <Widget>[
            // Track (surface-3)
            Container(color: palette.surface3),
            // Fill (accent), animating width over 1 s linear
            AnimatedFractionallySizedBox(
              widthFactor: progress,
              heightFactor: 1.0,
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.acc,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
