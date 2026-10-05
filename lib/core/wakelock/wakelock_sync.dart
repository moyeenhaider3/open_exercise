// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of openGym keep-awake behavior (App.jsx:129, lib/wakelock.js).
///
/// Keeps screen on while workout is active and keepAwake is not false.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gym_state.dart';
import '../state/gym_state_cubit.dart';

final class WakelockSync {
  WakelockSync._({
    required this._subscription,
    required this._lifecycleListener,
  });

  final StreamSubscription<GymState> _subscription;
  final AppLifecycleListener _lifecycleListener;
  bool _currentWanted = false;

  static WakelockSync start(GymStateCubit cubit) {
    bool computeWanted(GymState state) {
      return state.active != null && state.keepAwake != false;
    }

    Future<void> syncWakelock(bool wanted) async {
      try {
        if (wanted) {
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
      } catch (_) {
        // Silently swallow errors (e.g. iOS Low Power Mode refuses lock)
      }
    }

    late final WakelockSync instance;

    final initialWanted = computeWanted(cubit.state);
    syncWakelock(initialWanted);

    final sub = cubit.stream.listen((state) {
      final wanted = computeWanted(state);
      if (wanted != instance._currentWanted) {
        instance._currentWanted = wanted;
        syncWakelock(wanted);
      }
    });

    final listener = AppLifecycleListener(
      onResume: () {
        if (instance._currentWanted) {
          syncWakelock(true);
        }
      },
    );

    instance = WakelockSync._(
      subscription: sub,
      lifecycleListener: listener,
    );
    instance._currentWanted = initialWanted;

    return instance;
  }

  void dispose() {
    _subscription.cancel();
    _lifecycleListener.dispose();
  }
}
