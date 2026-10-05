// SPDX-License-Identifier: AGPL-3.0-or-later

/// Lifecycle forwarding (hidden/shown) and rest-over toast host.
///
/// Wraps the shell body to forward [AppLifecycleListener] events to
/// [WorkoutTimerBloc] and display the 'Rest over — next set!' toast.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../bloc/workout_timer_bloc.dart';
import '../../bloc/workout_timer_event.dart';
import '../../bloc/workout_timer_state.dart';

/// Stateful host that:
/// 1. Forwards [AppLifecycleState.hidden] → [WorkoutTimerAppHidden] and
///    [AppLifecycleState.resumed/show] → [WorkoutTimerAppShown].
/// 2. Listens for [WorkoutTimerRestOver] signal and shows the rest-over toast.
class WorkoutTimerHost extends StatefulWidget {
  const WorkoutTimerHost({super.key, required this.child});

  final Widget child;

  @override
  State<WorkoutTimerHost> createState() => _WorkoutTimerHostState();
}

class _WorkoutTimerHostState extends State<WorkoutTimerHost> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onHide: () => context.read<WorkoutTimerBloc>().add(const WorkoutTimerAppHidden()),
      onShow: () => context.read<WorkoutTimerBloc>().add(const WorkoutTimerAppShown()),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutTimerBloc, WorkoutTimerState>(
      listenWhen: (WorkoutTimerState prev, WorkoutTimerState curr) =>
          curr.signal is WorkoutTimerRestOver && prev.seq != curr.seq,
      listener: (BuildContext ctx, WorkoutTimerState state) {
        showToast(ctx, t('Rest over — next set!'));
      },
      child: widget.child,
    );
  }
}
