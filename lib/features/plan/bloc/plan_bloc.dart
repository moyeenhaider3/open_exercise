// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/format/glyphs.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/starter_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'plan_event.dart';
import 'plan_state.dart';

/// App-scoped BLoC managing the Plan screen and plan sheets.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Starter plan construction delegates to [JsEngineService] (JS-04).
/// Mirrors `../openGym/frontend/src/views/Plan.jsx`.
class PlanBloc extends Bloc<PlanEvent, PlanState> {
  PlanBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        // ignore: prefer_initializing_formals
        _engine = engine,
        super(_stateFrom(gymState.state)) {
    on<PlanEvent>(_onEvent, transformer: _sequential<PlanEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(PlanGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  StreamSubscription<GymState>? _subscription;

  int _seq = 0;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  /// Projects [GymState] into [PlanState].
  /// Mirrors Plan.jsx's derived dayRoutines computation.
  static PlanState _stateFrom(GymState s) {
    final List<Routine> routines = s.routines ?? const <Routine>[];
    final List<int> dayOrder = weekOrder(weekStartOf(s));
    final Map<int, List<Routine>> dayRoutines = <int, List<Routine>>{};
    for (final int day in dayOrder) {
      final List<String> ids = s.weekRoutineIds(day);
      // Drop stale ids exactly like Plan.jsx's filter(Boolean):
      final List<Routine> resolved = ids
          .map((String id) => routines.firstWhereOrNull((Routine r) => r.id == id))
          .whereType<Routine>()
          .toList();
      if (resolved.isNotEmpty) {
        dayRoutines[day] = resolved;
      }
    }
    return PlanState(
      routines: routines,
      dayOrder: dayOrder,
      dayRoutines: dayRoutines,
    );
  }

  void _emitSignal(PlanSignal sig, Emitter<PlanState> emit) {
    _seq++;
    emit(_stateFrom(_gymState.state).withSignal(sig).copyWith(seq: _seq));
  }

  Future<void> _onEvent(PlanEvent event, Emitter<PlanState> emit) async {
    switch (event) {
      case PlanGymStateChanged(:final GymState state):
        emit(_stateFrom(state).copyWith(seq: _seq));
      case PlanRoutineAdded():
        await _onRoutineAdded(emit);
      case PlanRoutineMoved(:final int index, :final int delta):
        await _onRoutineMoved(index, delta);
      case PlanDayAssigned(:final int day, :final String? routineId):
        await _onDayAssigned(day, routineId);
      case PlanDayRoutineAdded(:final int day, :final String routineId):
        await _onDayRoutineAdded(day, routineId);
      case PlanDayRoutineRemoved(:final int day, :final String routineId):
        await _onDayRoutineRemoved(day, routineId);
      case PlanStarterLoadRequested(:final String planId):
        await _onStarterLoadRequested(planId, emit);
      case PlanStarterLoaded(:final String planId):
        await _onStarterLoaded(planId, emit);
    }
  }

  /// Adds a new empty routine and signals navigation to it.
  /// Ported from `../openGym/frontend/src/views/Plan.jsx` addRoutine.
  Future<void> _onRoutineAdded(Emitter<PlanState> emit) async {
    final String id = uid();
    await _gymState.mutate((GymState s) {
      final List<Routine> next = List<Routine>.from(s.routines ?? const <Routine>[]);
      next.add(Routine(
        id: id,
        name: t('New routine'),
        emoji: kDefaultGlyph,
        ex: const <RoutineExercise>[],
      ));
      return s.copyWith(routines: next);
    });
    _emitSignal(PlanNavigateToRoutineSignal(id), emit);
  }

  /// Swaps a routine with its neighbour (moveRoutine).
  /// Ported from `../openGym/frontend/src/views/Plan.jsx` moveRoutine.
  Future<void> _onRoutineMoved(int index, int delta) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines = List<Routine>.from(s.routines ?? const <Routine>[]);
      final int to = index + delta;
      if (to < 0 || to >= routines.length) return s;
      final Routine moved = routines.removeAt(index);
      routines.insert(to, moved);
      return s.copyWith(routines: routines);
    });
  }

  /// Sets a day to exactly one routine id (or clears it).
  /// Ported from `../openGym/frontend/src/sheets.jsx` DayAssign.set.
  Future<void> _onDayAssigned(int day, String? routineId) async {
    await _gymState.mutate((GymState s) {
      if (routineId == null || routineId.isEmpty) {
        return s.withWeekDay(day, const <String>[]);
      }
      return s.withWeekDay(day, <String>[routineId]);
    });
  }

  /// Appends a routine id to a weekday's list.
  /// Ported from `../openGym/frontend/src/sheets.jsx` DayAddRoutine.add.
  Future<void> _onDayRoutineAdded(int day, String routineId) async {
    await _gymState.mutate((GymState s) {
      final List<String> cur = List<String>.from(s.weekRoutineIds(day));
      cur.add(routineId);
      return s.withWeekDay(day, cur);
    });
  }

  /// Removes a routine id from a weekday, deleting the key when empty.
  /// Ported from `../openGym/frontend/src/views/Plan.jsx` removeFromDay.
  Future<void> _onDayRoutineRemoved(int day, String routineId) async {
    await _gymState.mutate((GymState s) {
      final List<String> next =
          s.weekRoutineIds(day).where((String id) => id != routineId).toList();
      return s.withWeekDay(day, next);
    });
  }

  /// Checks if starter plan days are occupied; if so, signals for confirmation first.
  /// Ported from `../openGym/frontend/src/sheets.jsx` StarterPlanChooser.choose.
  Future<void> _onStarterLoadRequested(String planId, Emitter<PlanState> emit) async {
    final List<int>? days = _engine.starter.starterPlanDays(planId);
    if (days == null) return;
    final GymState s = _gymState.state;
    final List<Routine> routines = s.routines ?? const <Routine>[];
    // Mirrors the source: a day is "taken" only when it has an id that still resolves.
    final bool taken = days.any((int day) {
      return s.weekRoutineIds(day).any((String id) => routines.any((Routine r) => r.id == id));
    });
    if (!taken) {
      await _onStarterLoaded(planId, emit);
      return;
    }
    // Build the plan name for the confirm signal using the Dart PLAN_COPY equivalent.
    final String planName = _planName(planId);
    final List<String> dayNames =
        days.map((int d) => t(kDayNames[d])).toList();
    _emitSignal(PlanConfirmStarterSignal(planId: planId, planName: planName, dayNames: dayNames), emit);
  }

  /// Commits the starter plan: pushes routines and sets the week schedule.
  /// Ported from `../openGym/frontend/src/sheets.jsx` loadStarterPlan.
  Future<void> _onStarterLoaded(String planId, Emitter<PlanState> emit) async {
    final plan = _engine.starter.buildStarterPlan(planId);
    if (plan == null) return;
    await _gymState.mutate((GymState s) {
      final List<Routine> nextRoutines = List<Routine>.from(s.routines ?? const <Routine>[]);
      nextRoutines.addAll(plan.routines);
      GymState next = s.copyWith(routines: nextRoutines);
      for (final item in plan.schedule) {
        next = next.withWeekDay(item.day, <String>[item.routineId]);
      }
      return next;
    });
    _emitSignal(PlanToastSignal(t('{0} loaded', <Object?>[_planName(planId)])), emit);
  }

  /// PLAN_COPY name equivalents, verbatim from `../openGym/frontend/src/sheets.jsx` lines 103-107.
  static String _planName(String planId) {
    switch (planId) {
      case 'ppl':
        return t('Push / Pull / Legs');
      case 'upper-lower':
        return t('Upper / Lower');
      case 'full-body':
        return t('Full Body');
      case '5x5':
        return t('5×5');
      default:
        return planId;
    }
  }

  /// PLAN_COPY about strings from `../openGym/frontend/src/sheets.jsx` lines 103-107.
  static String planAbout(String planId) {
    switch (planId) {
      case 'ppl':
        return t('Push, pull and legs each get their own day.');
      case 'upper-lower':
        return t('Upper body twice, lower body twice.');
      case 'full-body':
        return t('Three sessions, the whole body each time.');
      case '5x5':
        return t('Five sets of five on the main barbell lifts.');
      default:
        return '';
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
