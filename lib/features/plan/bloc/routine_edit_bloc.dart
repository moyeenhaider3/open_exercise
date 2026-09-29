// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/equipment.dart';
import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/format/set_label.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'routine_edit_event.dart';
import 'routine_edit_state.dart';

/// Reorders a superset unit within the exercises list.
/// Ported from `../openGym/frontend/src/views/RoutineEdit.jsx:31-45` (reorderRoutineUnit).
List<RoutineExercise>? reorderRoutineUnit(
  HistoryJs history,
  List<RoutineExercise> exercises,
  int sourceIndex,
  int targetSlot,
) {
  if (exercises.isEmpty) return null;
  final List<List<int>> units = history.supersetUnits(exercises);
  final int sourcePosition =
      units.indexWhere((List<int> unit) => unit.contains(sourceIndex));
  if (sourcePosition < 0) return null;
  final List<List<int>> remaining = <List<int>>[];
  for (int p = 0; p < units.length; p++) {
    if (p != sourcePosition) remaining.add(units[p]);
  }
  final int slot = targetSlot.clamp(0, remaining.length);
  if (slot == sourcePosition) return null;
  final List<int> source = units[sourcePosition];
  final List<RoutineExercise> copy = List<RoutineExercise>.from(exercises);
  final List<RoutineExercise> moved =
      copy.sublist(source.first, source.first + source.length);
  copy.removeRange(source.first, source.first + source.length);
  int insertAt = 0;
  for (int p = 0; p < slot; p++) {
    insertAt += remaining[p].length;
  }
  copy.insertAll(insertAt, moved);
  return history.cleanupSg(copy);
}

/// Creates a deep copy of a routine with a new id and a "(Copy)" / "(Copy N)" suffix.
/// Ported from `../openGym/frontend/src/lib/routines.js:7-17` (copyRoutine).
Routine copyRoutine(Routine routine, String suffix) {
  final String esc = RegExp.escape(suffix);
  final RegExp regex = RegExp('^(.*) \\($esc(?: (\\d+))?\\)\$');
  final Match? m = regex.firstMatch(routine.name ?? '');
  final String nextName = m != null
      ? '${m.group(1)} ($suffix ${((int.tryParse(m.group(2) ?? '') ?? 1) + 1)})'
      : '${routine.name ?? ''} ($suffix)';
  return routine.copyWith(
    id: uid(),
    name: nextName,
    ex: routine.ex?.map((RoutineExercise e) => e.copyWith()).toList(),
  );
}

/// Screen-scoped BLoC managing the RoutineEdit screen.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] (D-04).
/// Delegates domain math, superset grouping, and unit moving to [HistoryJs] (JS-04).
/// Mirrors `../openGym/frontend/src/views/RoutineEdit.jsx`.
class RoutineEditBloc extends Bloc<RoutineEditEvent, RoutineEditState> {
  RoutineEditBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
    required ExerciseCatalogue catalogue,
    required this.routineId,
  })  : _gymState = gymState,
        _engine = engine,
        _catalogue = catalogue,
        super(_computeStateFrom(
          gymState.state,
          routineId,
          engine,
          catalogue,
        )) {
    on<RoutineEditEvent>(_onEvent, transformer: _sequential<RoutineEditEvent>());
    _subscription = _gymState.stream.listen((GymState s) {
      add(RoutineEditGymStateChanged(s));
    });
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  final ExerciseCatalogue _catalogue;
  final String routineId;
  StreamSubscription<GymState>? _subscription;

  int _seq = 0;

  static EventTransformer<E> _sequential<E>() =>
      (Stream<E> events, EventMapper<E> mapper) => events.asyncExpand(mapper);

  static RoutineEditState _computeStateFrom(
    GymState s,
    String routineId,
    JsEngineService engine,
    ExerciseCatalogue catalogue,
  ) {
    final Routine? r =
        s.routines?.firstWhereOrNull((Routine x) => x.id == routineId);
    if (r == null) {
      return const RoutineEditMissing();
    }
    final List<RoutineExercise> exercises = r.ex ?? const <RoutineExercise>[];
    final List<List<int>> units = engine.history.supersetUnits(exercises);
    final Map<int, int> unitIndex = <int, int>{};
    for (int u = 0; u < units.length; u++) {
      for (final int idx in units[u]) {
        unitIndex[idx] = u;
      }
    }
    final Set<int> unitFirst = units
        .where((List<int> u) => u.length > 1)
        .map((List<int> u) => u[0])
        .toSet();
    final Set<int> inSuperset = units
        .where((List<int> u) => u.length > 1)
        .expand((List<int> u) => u)
        .toSet();
    final EquipProfile? profile = activeProfile(s);
    final List<bool> noEquip = <bool>[];
    int missingCount = 0;
    final List<String> lines = <String>[];
    final String unit = s.unit ?? 'kg';
    for (final RoutineExercise e in exercises) {
      final ExerciseDef ex = catalogue.lookup(s, e.id ?? '');
      final bool missing = profile != null && !exAvailable(s, ex);
      noEquip.add(missing);
      if (missing) missingCount++;
      lines.add(exLine(engine, e, unit));
    }
    return RoutineEditReady(
      routine: r,
      units: units,
      unitIndex: unitIndex,
      unitFirst: unitFirst,
      inSuperset: inSuperset,
      profile: profile,
      missingCount: missingCount,
      noEquip: noEquip,
      lines: lines,
    );
  }

  RoutineEditState _computeState(GymState s) =>
      _computeStateFrom(s, routineId, _engine, _catalogue);

  void _emitSignal(RoutineEditSignal sig, Emitter<RoutineEditState> emit) {
    _seq++;
    final RoutineEditState current = _computeState(_gymState.state);
    if (current is RoutineEditReady) {
      emit(current.withSignal(sig).copyWith(seq: _seq));
    } else {
      emit(current);
    }
  }

  Future<void> _onEvent(
    RoutineEditEvent event,
    Emitter<RoutineEditState> emit,
  ) async {
    switch (event) {
      case RoutineEditGymStateChanged(:final GymState state):
        final RoutineEditState next = _computeState(state);
        if (next is RoutineEditReady) {
          emit(next.copyWith(seq: _seq));
        } else {
          emit(next);
        }
      case RoutineRenamed(:final String name):
        await _onRenamed(name);
      case RoutineGlyphChanged(:final String glyph):
        await _onGlyphChanged(glyph);
      case RoutineProgressionPolicyChanged(:final String policy):
        await _onProgressionPolicyChanged(policy);
      case RoutineExcludeChanged(:final bool v):
        await _onExcludeChanged(v);
      case RoutineExerciseAdded(
          :final String exId,
          :final RoutineExercise cfg,
          :final bool quick
        ):
        await _onExerciseAdded(exId, cfg, quick, emit);
      case RoutineExerciseConfigured(:final int i, :final RoutineExercise cfg):
        await _onExerciseConfigured(i, cfg);
      case RoutineExerciseRemoved(:final int i):
        await _onExerciseRemoved(i);
      case RoutineUnitMoved(:final int i, :final int dir):
        await _onUnitMoved(i, dir);
      case RoutineUnitReordered(
          :final int sourceUnit,
          :final int targetUnit
        ):
        await _onUnitReordered(sourceUnit, targetUnit);
      case RoutineLinkToggled(:final int i):
        await _onLinkToggled(i);
      case RoutineCopied():
        await _onCopied(emit);
      case RoutineDeleted():
        await _onDeleted(emit);
    }
  }

  Future<void> _onRenamed(String name) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final String trimmed = name.trim();
      routines[idx] = routines[idx]
          .copyWith(name: trimmed.isEmpty ? t('Routine') : trimmed);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onGlyphChanged(String glyph) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      routines[idx] = routines[idx].copyWith(emoji: glyph);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onProgressionPolicyChanged(String policy) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      routines[idx] =
          routines[idx].withExtraFields(<String, Object?>{'prog': policy});
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onExcludeChanged(bool v) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      if (v) {
        routines[idx] = routines[idx].withExtraFields(
            <String, Object?>{'excludeFromProgression': true});
      } else {
        routines[idx] = routines[idx].withExtraFields(
          const <String, Object?>{},
          remove: const <String>['excludeFromProgression'],
        );
      }
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onExerciseAdded(
    String exId,
    RoutineExercise cfg,
    bool quick,
    Emitter<RoutineEditState> emit,
  ) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      ex.add(cfg.copyWith(id: exId));
      routines[idx] = r.copyWith(ex: ex);
      return s.copyWith(routines: routines);
    });
    if (quick) {
      final ExerciseDef exDef = _catalogue.lookup(_gymState.state, exId);
      final Routine? r = _gymState.state.routines
          ?.firstWhereOrNull((Routine x) => x.id == routineId);
      _emitSignal(
        RoutineEditToastSignal(
          t('“{0}” added to {1}', <Object?>[
            _catalogue.exerciseNameFor(exDef),
            r?.name ?? t('Routine'),
          ]),
        ),
        emit,
      );
    }
  }

  Future<void> _onExerciseConfigured(int i, RoutineExercise cfg) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      if (i < 0 || i >= ex.length) return s;
      final RoutineExercise current = ex[i];
      ex[i] = cfg.copyWith(
        id: current.id,
        sg: current.sg,
      );
      routines[idx] = r.copyWith(ex: ex);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onExerciseRemoved(int i) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      if (i < 0 || i >= ex.length) return s;
      ex.removeAt(i);
      final List<RoutineExercise> cleaned = _engine.history.cleanupSg(ex);
      routines[idx] = r.copyWith(ex: cleaned);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onUnitMoved(int i, int dir) async {
    final Routine? currentRoutine = _gymState.state.routines
        ?.firstWhereOrNull((Routine x) => x.id == routineId);
    final List<RoutineExercise>? currentEx = currentRoutine?.ex;
    if (currentEx == null) return;
    final List<RoutineExercise>? guarded =
        _engine.history.moveSupersetUnit(currentEx, i, dir);
    if (guarded == null) return;

    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      final List<RoutineExercise>? reordered =
          _engine.history.moveSupersetUnit(ex, i, dir);
      if (reordered == null) return s;
      final List<RoutineExercise> cleaned =
          _engine.history.cleanupSg(reordered);
      routines[idx] = r.copyWith(ex: cleaned);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onUnitReordered(int sourceUnit, int targetUnit) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      final List<List<int>> units = _engine.history.supersetUnits(ex);
      if (sourceUnit < 0 || sourceUnit >= units.length) return s;
      final int sourceIndex = units[sourceUnit].first;
      final List<RoutineExercise>? reordered = reorderRoutineUnit(
        _engine.history,
        ex,
        sourceIndex,
        targetUnit,
      );
      if (reordered == null) return s;
      routines[idx] = r.copyWith(ex: reordered);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onLinkToggled(int i) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      final int idx = routines.indexWhere((Routine x) => x.id == routineId);
      if (idx < 0) return s;
      final Routine r = routines[idx];
      final List<RoutineExercise> ex =
          List<RoutineExercise>.from(r.ex ?? const <RoutineExercise>[]);
      if (i < 1 || i >= ex.length) return s;
      final RoutineExercise cur = ex[i];
      final RoutineExercise prev = ex[i - 1];
      final List<RoutineExercise> nextEx;
      if (cur.sg != null && prev.sg != null && cur.sg == prev.sg) {
        nextEx = _engine.history.unpairSuperset(ex, i);
      } else {
        nextEx = _engine.history.pairAdjacent(ex, i - 1, i);
      }
      routines[idx] = r.copyWith(ex: nextEx);
      return s.copyWith(routines: routines);
    });
  }

  Future<void> _onCopied(Emitter<RoutineEditState> emit) async {
    final Routine? r = _gymState.state.routines
        ?.firstWhereOrNull((Routine x) => x.id == routineId);
    if (r == null) return;
    final Routine copy = copyRoutine(r, t('Copy'));
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      routines.add(copy);
      return s.copyWith(routines: routines);
    });
    _emitSignal(
      RoutineEditNavigateSignal(AppRoutes.routinePath(copy.id!)),
      emit,
    );
  }

  Future<void> _onDeleted(Emitter<RoutineEditState> emit) async {
    await _gymState.mutate((GymState s) {
      final List<Routine> routines =
          List<Routine>.from(s.routines ?? const <Routine>[]);
      routines.removeWhere((Routine x) => x.id == routineId);

      final Map<String, Object> nextWeek = <String, Object>{};
      if (s.week != null) {
        for (final MapEntry<String, Object> entry in s.week!.entries) {
          final Object val = entry.value;
          final List<String> list = val is List
              ? val
                  .whereType<String>()
                  .where((String id) => id != routineId)
                  .toList()
              : (val is String && val != routineId
                  ? <String>[val]
                  : <String>[]);
          if (list.isNotEmpty) {
            nextWeek[entry.key] = list;
          }
        }
      }

      final Map<String, String> nextDayPlan = <String, String>{};
      if (s.dayPlan != null) {
        for (final MapEntry<String, String> entry in s.dayPlan!.entries) {
          if (entry.value != routineId) {
            nextDayPlan[entry.key] = entry.value;
          }
        }
      }

      return s.copyWith(
        routines: routines,
        week: nextWeek,
        dayPlan: nextDayPlan,
      );
    });
    _emitSignal(const RoutineEditNavigateSignal(AppRoutes.plan), emit);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
