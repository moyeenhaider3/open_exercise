// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/muscle_models.dart';
import '../../../core/js/modules/muscle_view_js.dart';
import '../../../core/js/modules/muscles_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'muscle_balance_event.dart';
import 'muscle_balance_state.dart';

/// Card-scoped BLoC managing Muscle balance / Fatigue / Strength view and selections.
///
/// All domain numbers and shade levels delegate to [JsEngineService] (JS-04).
/// Selections are card-local and reset on unmount.
/// Periodic 60 s tick refreshes time-dependent fatigue and strength data.
/// Mirrors `../openGym/frontend/src/views/Stats.jsx` lines 59-66 and 100-143.
class MuscleBalanceBloc extends Bloc<MuscleBalanceEvent, MuscleBalanceState> {
  MuscleBalanceBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        _engine = engine,
        super(
          _derive(
            gymState.state,
            'balance',
            7,
            false,
            null,
            engine,
          ),
        ) {
    on<MuscleBalanceEvent>(_onEvent, transformer: _sequential<MuscleBalanceEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(MuscleBalanceGymStateChanged(s));
    });
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(const MuscleBalanceTicked());
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  StreamSubscription<GymState>? _subscription;
  Timer? _timer;

  String _view = 'balance';
  int _win = 7;
  bool _hard = false;
  String? _selected;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(
    MuscleBalanceEvent event,
    Emitter<MuscleBalanceState> emit,
  ) async {
    switch (event) {
      case MuscleBalanceGymStateChanged(:final GymState state):
        emit(_derive(state, _view, _win, _hard, _selected, _engine));
      case MuscleBalanceViewChanged(:final String view):
        _view = view;
        emit(_derive(_gymState.state, _view, _win, _hard, _selected, _engine));
      case MuscleBalanceWindowChanged(:final int win):
        _win = win;
        _selected = null;
        emit(_derive(_gymState.state, _view, _win, _hard, _selected, _engine));
      case MuscleBalanceHardToggled():
        _hard = !_hard;
        _selected = null;
        emit(_derive(_gymState.state, _view, _win, _hard, _selected, _engine));
      case MuscleBalanceMuscleToggled(:final String slug):
        _selected = _selected == slug ? null : slug;
        emit(_derive(_gymState.state, _view, _win, _hard, _selected, _engine));
      case MuscleBalanceTicked():
        emit(_derive(_gymState.state, _view, _win, _hard, _selected, _engine));
    }
  }

  static MuscleBalanceReady _derive(
    GymState s,
    String view,
    int win,
    bool hard,
    String? selected,
    JsEngineService engine,
  ) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final String today = todayIso();

    final MuscleBalanceView balance = engine.muscleView.muscleBalance(
      s,
      win: win,
      hard: hard,
      nowMs: nowMs,
      todayIso: today,
    );
    final FatigueView fatigue = engine.muscleView.fatigueView(s, nowMs);
    final StrengthView strength = engine.muscleView.strengthView(s, nowMs, selected);
    final Map<String, String> muscleNames = engine.muscles.muscleName;

    return MuscleBalanceReady(
      view: view,
      win: win,
      hard: hard,
      selected: selected,
      body: s.body,
      unit: s.unit ?? 'kg',
      balance: balance,
      fatigue: fatigue,
      strength: strength,
      muscleNames: muscleNames,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
