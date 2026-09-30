// SPDX-License-Identifier: AGPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/history_models.dart';
import '../../../core/js/models/phase31_models.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/view_aggregates_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/workout.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'home_event.dart';
import 'home_state.dart';

/// App-scoped BLoC managing Home screen derived data and week strip navigation.
///
/// All domain aggregates and calculations delegate to [JsEngineService] (JS-04).
/// Week offset is screen-local and not persisted to [GymState].
/// Mirrors `../openGym/frontend/src/views/Home.jsx`.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        _engine = engine,
        super(_deriveState(gymState.state, 0, engine)) {
    on<HomeEvent>(_onEvent, transformer: _sequential<HomeEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(HomeGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  StreamSubscription<GymState>? _subscription;

  int _weekOffset = 0;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(HomeEvent event, Emitter<HomeState> emit) async {
    switch (event) {
      case HomeGymStateChanged(:final GymState state):
        emit(_deriveState(state, _weekOffset, _engine));
      case HomeWeekOffsetChanged(:final int delta):
        _weekOffset += delta;
        emit(_deriveState(_gymState.state, _weekOffset, _engine));
    }
  }

  /// Projects [GymState] and current [offset] into [HomeReady].
  /// Mirrors `../openGym/frontend/src/views/Home.jsx` lines 14-60.
  static HomeReady _deriveState(GymState s, int offset, JsEngineService engine) {
    final String today = todayIso();
    final List<Routine> todayRoutines = engine.history.effectiveRoutines(s, today);
    final List<String> todayIds = engine.history.effectiveRoutineIds(s, today);
    final bool todayOverridden = s.dayPlan?.containsKey(today) == true;

    final TrainingDay? next = (s.active == null && todayRoutines.isEmpty)
        ? engine.history.nextTrainingDay(s, today)
        : null;

    final List<Workout> workouts = s.workouts ?? const <Workout>[];
    Workout? doneToday;
    for (int i = workouts.length - 1; i >= 0; i--) {
      if (workouts[i].d == today) {
        doneToday = workouts[i];
        break;
      }
    }

    final BodyweightEntry? bw = engine.history.lastBW(s);
    final HomeView view = engine.viewAgg.homeView(s, today);
    final int streak = engine.history.streakWeeks(s);

    final int ws = weekStartOf(s);
    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final int jsDay = todayDate.weekday % 7;
    final int offsetFromWs = weekDayOffset(jsDay, ws);
    final DateTime wkStart = DateTime(
      todayDate.year,
      todayDate.month,
      todayDate.day - offsetFromWs + (offset * 7),
    );
    final DateTime wkEnd = DateTime(wkStart.year, wkStart.month, wkStart.day + 6);

    final Set<String> doneDays = <String>{
      for (final Workout w in workouts)
        if (w.d != null) w.d!,
    };

    final List<HomeStripDay> stripDays = <HomeStripDay>[];
    for (int i = 0; i < 7; i++) {
      final DateTime d = DateTime(wkStart.year, wkStart.month, wkStart.day + i);
      final String iso = isoOf(d);
      final bool eff = engine.history.effectiveRoutineIds(s, iso).isNotEmpty;
      final bool ovr = s.dayPlan?.containsKey(iso) == true;
      final bool done = doneDays.contains(iso);
      stripDays.add(HomeStripDay(
        iso: iso,
        weekday: d.weekday % 7,
        dayOfMonth: d.day,
        planned: eff,
        overridden: ovr,
        done: done,
      ));
    }

    final String weekLabel = offset == 0
        ? t('This week')
        : '${wkStart.day} ${kMonths[wkStart.month - 1]} – ${wkEnd.day} ${kMonths[wkEnd.month - 1]}';

    return HomeReady(
      weekOffset: offset,
      todayIso: today,
      todayRoutines: todayRoutines,
      todayIds: todayIds,
      todayOverridden: todayOverridden,
      next: next,
      doneToday: doneToday,
      bw: bw,
      view: view,
      streak: streak,
      stripDays: stripDays,
      weekStart: wkStart,
      weekEnd: wkEnd,
      weekLabel: weekLabel,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
