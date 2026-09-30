// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/js/models/history_models.dart';
import '../../../core/js/models/phase31_models.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/workout.dart';

/// Single day cell data inside the week strip.
class HomeStripDay extends Equatable {
  const HomeStripDay({
    required this.iso,
    required this.weekday,
    required this.dayOfMonth,
    required this.planned,
    required this.overridden,
    required this.done,
  });

  /// ISO 8601 date string (YYYY-MM-DD).
  final String iso;

  /// JS weekday index (0..6 where 0 is Sunday).
  final int weekday;

  /// Day-of-month integer (1..31).
  final int dayOfMonth;

  /// True if at least one routine is scheduled for this day.
  final bool planned;

  /// True if the day has a specific date override in dayPlan.
  final bool overridden;

  /// True if at least one completed workout was logged on this day.
  final bool done;

  @override
  List<Object?> get props => <Object?>[
        iso,
        weekday,
        dayOfMonth,
        planned,
        overridden,
        done,
      ];
}

/// Sealed base class for states emitted by [HomeBloc].
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial uninitialized state before first GymState projection.
final class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Ready state containing all derived metrics and strip days for the Home screen.
final class HomeReady extends HomeState {
  const HomeReady({
    required this.weekOffset,
    required this.todayIso,
    required this.todayRoutines,
    required this.todayIds,
    required this.todayOverridden,
    this.next,
    this.doneToday,
    this.bw,
    required this.view,
    required this.streak,
    required this.stripDays,
    required this.weekStart,
    required this.weekEnd,
    required this.weekLabel,
  });

  /// Offset in weeks from the current week (0 = this week).
  final int weekOffset;

  /// Today's date in YYYY-MM-DD format.
  final String todayIso;

  /// Routines scheduled for today.
  final List<Routine> todayRoutines;

  /// Routine IDs scheduled for today.
  final List<String> todayIds;

  /// True if today has an override in dayPlan.
  final bool todayOverridden;

  /// Next scheduled training day (only when no active session and no today routines).
  final TrainingDay? next;

  /// The most recent workout completed today, if any.
  final Workout? doneToday;

  /// Most recent bodyweight entry.
  final BodyweightEntry? bw;

  /// Precomputed aggregates from JS engine (delta, deltaAbs, wThisWeek, plannedPerWeek, bwPoints, goal).
  final HomeView view;

  /// Consecutive training weeks streak.
  final int streak;

  /// 7 day cells for the current shown week.
  final List<HomeStripDay> stripDays;

  /// Starting date of the shown week.
  final DateTime weekStart;

  /// Ending date of the shown week.
  final DateTime weekEnd;

  /// Localized or formatted week label ('This week' or 'D Mon – D Mon').
  final String weekLabel;

  @override
  List<Object?> get props => <Object?>[
        weekOffset,
        todayIso,
        todayRoutines,
        todayIds,
        todayOverridden,
        next,
        doneToday,
        bw,
        view,
        streak,
        stripDays,
        weekStart,
        weekEnd,
        weekLabel,
      ];
}
