// SPDX-License-Identifier: AGPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/equipment.dart';
import '../../../core/format/workout_controls.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/units_js.dart';
import '../../../core/models/default_state.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/state_parts.dart';
import '../../../core/state/gym_state_cubit.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// App-scoped BLoC managing application settings and configuration.
///
/// Modifies persisted state exclusively via [GymStateCubit.mutate] and
/// [GymStateCubit.replaceState] (D-04).
/// Unit conversion delegates exclusively to QuickJS via [UnitsJs] (JS-04).
/// Theme and accent reuse [ShellBloc] events.
/// Ports `../openGym/frontend/src/views/Settings.jsx`.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GymStateCubit gymState,
    required JsEngineService engine,
  })  : _gymState = gymState,
        _engine = engine,
        super(const SettingsState()) {
    on<SettingsEvent>(_onEvent);
  }

  final GymStateCubit _gymState;
  final JsEngineService _engine;
  int _seq = 0;

  Future<void> _onEvent(
    SettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    switch (event) {
      case SettingsUnitSwitched():
        await _onUnitSwitched(event);
      case SettingsGeneralChanged():
        await _onGeneralChanged(event);
      case SettingsWorkoutChanged():
        await _onWorkoutChanged(event);
      case SettingsWorkoutControlsChanged():
        await _onWorkoutControlsChanged(event);
      case SettingsBodyChanged():
        await _onBodyChanged(event);
      case SettingsEquipFilterToggled():
        await _onEquipFilterToggled(event);
      case SettingsActiveEquipChanged():
        await _onActiveEquipChanged(event);
      case SettingsEquipProfileSaved():
        await _onEquipProfileSaved(event);
      case SettingsEquipProfileDeleted():
        await _onEquipProfileDeleted(event);
      case SettingsResetConfirmed():
        await _onResetConfirmed(emit);
    }
  }

  /// Switches unit between 'kg' and 'lb'.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:37-47 switchUnit.
  Future<void> _onUnitSwitched(SettingsUnitSwitched event) async {
    final GymState current = _gymState.state;
    if (event.unit == current.unit) return;

    if (event.convert) {
      final GymState converted = _engine.units.convertStateUnit(current, event.unit);
      await _gymState.replaceState(converted);
    } else {
      await _gymState.mutate((GymState s) => s.copyWith(unit: event.unit));
    }
  }

  /// Applies General section settings changes.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:245-285.
  Future<void> _onGeneralChanged(SettingsGeneralChanged event) async {
    await _gymState.mutate((GymState s) {
      return s.copyWith(
        wdec: event.wdec ?? s.wdec,
        weekStart: event.weekStart ?? s.weekStart,
        checkIn: event.checkIn ?? s.checkIn,
      );
    });
  }

  /// Applies During a workout section settings changes.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:287-349.
  Future<void> _onWorkoutChanged(SettingsWorkoutChanged event) async {
    await _gymState.mutate((GymState s) {
      final Map<String, Object?>? nextExtra = event.effort != null
          ? (Map<String, Object?>.from(s.extra)..remove('showRir'))
          : null;

      return s.copyWith(
        weighIn: event.weighIn ?? s.weighIn,
        workoutView: event.workoutView ?? s.workoutView,
        restSec: event.restSec ?? s.restSec,
        restPauseSec: event.restPauseSec ?? s.restPauseSec,
        keepAwake: event.keepAwake ?? s.keepAwake,
        gifSize: event.gifSize ?? s.gifSize,
        sound: event.sound ?? s.sound,
        soundOnSilent: event.soundOnSilent ?? s.soundOnSilent,
        timerFlash: event.timerFlash ?? s.timerFlash,
        effort: event.effort ?? s.effort,
        extra: nextExtra,
      );
    });
  }

  /// Toggles individual workout control setting.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:462.
  Future<void> _onWorkoutControlsChanged(SettingsWorkoutControlsChanged event) async {
    await _gymState.mutate((GymState s) {
      final WorkoutControlsView currentWc = workoutControls(s);
      return s.copyWith(
        wc: WorkoutControls(
          steppers: event.key == 'steppers' ? event.value : currentWc.steppers,
          setShortcuts: event.key == 'setShortcuts' ? event.value : currentWc.setShortcuts,
          pairButtons: event.key == 'pairButtons' ? event.value : currentWc.pairButtons,
          exerciseButtons: event.key == 'exerciseButtons' ? event.value : currentWc.exerciseButtons,
          extra: s.wc?.extra ?? const <String, Object?>{},
        ),
      );
    });
  }

  /// Updates body diagram preference.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:360.
  Future<void> _onBodyChanged(SettingsBodyChanged event) async {
    await _gymState.mutate((GymState s) => s.copyWith(body: event.body));
  }

  /// Toggles equipment filtering.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:635.
  Future<void> _onEquipFilterToggled(SettingsEquipFilterToggled event) async {
    await _gymState.mutate((GymState s) => s.copyWith(equipFilterOn: event.on));
  }

  /// Changes active equipment profile ID.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:648.
  Future<void> _onActiveEquipChanged(SettingsActiveEquipChanged event) async {
    await _gymState.mutate((GymState s) => s.copyWith(activeEquipId: event.id));
  }

  /// Creates or updates an equipment profile.
  /// Mirrors `../openGym/frontend/src/sheets.jsx`:1076-1116 EquipmentProfileSheet.
  Future<void> _onEquipProfileSaved(SettingsEquipProfileSaved event) async {
    final String trimmed = event.name.trim();
    if (trimmed.isEmpty) return;

    await _gymState.mutate((GymState s) {
      final List<EquipProfile> list = List<EquipProfile>.from(s.equipProfiles ?? const <EquipProfile>[]);
      if (event.id != null) {
        final int idx = list.indexWhere((EquipProfile p) => p.id == event.id);
        if (idx >= 0) {
          list[idx] = list[idx].copyWith(name: trimmed, equipment: event.equipment);
        }
        return s.copyWith(equipProfiles: list);
      } else {
        final EquipProfile created = newProfile(trimmed).copyWith(equipment: event.equipment);
        list.add(created);
        final String? nextActive = s.activeEquipId ?? created.id;
        return s.copyWith(equipProfiles: list, activeEquipId: nextActive);
      }
    });
  }

  /// Deletes an equipment profile and repairs activeEquipId.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:636-644.
  Future<void> _onEquipProfileDeleted(SettingsEquipProfileDeleted event) async {
    await _gymState.mutate((GymState s) {
      final List<EquipProfile> list =
          (s.equipProfiles ?? const <EquipProfile>[]).where((EquipProfile p) => p.id != event.id).toList();
      String? nextActive = s.activeEquipId;
      if (nextActive == event.id) {
        nextActive = list.isNotEmpty ? list.first.id : null;
      }
      return s.copyWith(
        equipProfiles: list,
        activeEquipId: nextActive,
      );
    });
  }

  /// Resets all data to openGym default state.
  /// Mirrors `../openGym/frontend/src/views/Settings.jsx`:161-184 resetEverything.
  Future<void> _onResetConfirmed(Emitter<SettingsState> emit) async {
    final GymState defaults = GymState.fromJson(overlayOnDefaults(const <String, Object?>{}));
    await _gymState.replaceState(defaults);
    _seq++;
    emit(state.copyWith(seq: _seq, signal: const SettingsResetDone()));
  }
}
