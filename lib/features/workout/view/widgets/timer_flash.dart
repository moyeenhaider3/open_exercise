// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of components/TimerFlash.jsx.
///
/// Applies [opposite, original, opposite, original] theme steps at
/// 0 ms, 600 ms, 1200 ms and 1800 ms whenever [flashId] changes to
/// a new non-zero value, then restores the user's themeMode.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Widget that wraps [MaterialApp.router] and fires a 4-step theme flash on
/// each new [flashId].
///
/// [builder] receives the effective [ThemeMode] and a [flashing] flag so the
/// caller can set [themeAnimationDuration] to [Duration.zero] while flashing.
class TimerFlash extends StatefulWidget {
  const TimerFlash({
    super.key,
    required this.flashId,
    required this.themeMode,
    required this.builder,
  });

  /// Increments each time a flash should fire (from WorkoutTimerBloc.flashId).
  final int flashId;

  /// The user's chosen theme mode.
  final ThemeMode themeMode;

  /// Builder receiving (effectiveMode, flashing) — use effectiveMode as
  /// themeMode and Duration.zero as themeAnimationDuration while flashing.
  final Widget Function(ThemeMode effectiveMode, bool flashing) builder;

  @override
  State<TimerFlash> createState() => _TimerFlashState();
}

class _TimerFlashState extends State<TimerFlash> {
  late ThemeMode _effectiveMode;
  bool _flashing = false;
  int _lastFlashId = 0;
  final List<Timer> _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _effectiveMode = widget.themeMode;
  }

  @override
  void didUpdateWidget(TimerFlash old) {
    super.didUpdateWidget(old);
    if (widget.themeMode != old.themeMode && !_flashing) {
      _effectiveMode = widget.themeMode;
    }
    if (widget.flashId != _lastFlashId && widget.flashId != 0) {
      _lastFlashId = widget.flashId;
      _startFlash();
    }
  }

  /// Resolves the user's current brightness for the opposite calculation.
  Brightness _resolveBrightness() {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  ThemeMode _opposite(Brightness brightness) {
    return brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode _original() {
    return widget.themeMode;
  }

  void _startFlash() {
    _cancelTimers();
    final Brightness brightness = _resolveBrightness();
    // Steps: [opposite, original, opposite, original] at i*600 ms
    final List<ThemeMode> steps = <ThemeMode>[
      _opposite(brightness), // 0 ms
      _original(), // 600 ms
      _opposite(brightness), // 1200 ms
      _original(), // 1800 ms
    ];

    for (int i = 0; i < steps.length; i++) {
      final ThemeMode step = steps[i];
      final bool isLast = i == steps.length - 1;
      _timers.add(Timer(Duration(milliseconds: i * 600), () {
        if (!mounted) return;
        setState(() {
          _effectiveMode = step;
          _flashing = !isLast;
        });
      }));
    }
  }

  void _cancelTimers() {
    for (final Timer t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _effectiveMode = widget.themeMode;
    _flashing = false;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_effectiveMode, _flashing);
  }
}
