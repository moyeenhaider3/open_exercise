// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

/// Sealed base class for all SettingsBloc events.
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Dispatched to switch weight unit between 'kg' and 'lb', with or without converting numbers.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:37-47 switchUnit.
final class SettingsUnitSwitched extends SettingsEvent {
  const SettingsUnitSwitched(
    this.unit, {
    required this.convert,
  });

  final String unit;
  final bool convert;

  @override
  List<Object?> get props => <Object?>[unit, convert];
}

/// Dispatched when General section settings change (decimals, week start, check-in card).
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:245-285.
final class SettingsGeneralChanged extends SettingsEvent {
  const SettingsGeneralChanged({
    this.wdec,
    this.weekStart,
    this.checkIn,
  });

  final num? wdec;
  final int? weekStart;
  final bool? checkIn;

  @override
  List<Object?> get props => <Object?>[wdec, weekStart, checkIn];
}

/// Dispatched when During a workout section settings change.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:287-349.
final class SettingsWorkoutChanged extends SettingsEvent {
  const SettingsWorkoutChanged({
    this.weighIn,
    this.workoutView,
    this.restSec,
    this.restPauseSec,
    this.keepAwake,
    this.gifSize,
    this.sound,
    this.soundOnSilent,
    this.timerFlash,
    this.effort,
  });

  final bool? weighIn;
  final String? workoutView;
  final num? restSec;
  final num? restPauseSec;
  final bool? keepAwake;
  final String? gifSize;
  final bool? sound;
  final bool? soundOnSilent;
  final bool? timerFlash;
  final String? effort;

  @override
  List<Object?> get props => <Object?>[
        weighIn,
        workoutView,
        restSec,
        restPauseSec,
        keepAwake,
        gifSize,
        sound,
        soundOnSilent,
        timerFlash,
        effort,
      ];
}

/// Dispatched when an individual workout control toggle changes in the sheet.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:462.
final class SettingsWorkoutControlsChanged extends SettingsEvent {
  const SettingsWorkoutControlsChanged(this.key, this.value);

  final String key;
  final bool value;

  @override
  List<Object?> get props => <Object?>[key, value];
}

/// Dispatched when body diagram selection changes.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:360.
final class SettingsBodyChanged extends SettingsEvent {
  const SettingsBodyChanged(this.body);

  final String body;

  @override
  List<Object?> get props => <Object?>[body];
}

/// Dispatched when equipment filter toggle is flipped.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:635.
final class SettingsEquipFilterToggled extends SettingsEvent {
  const SettingsEquipFilterToggled(this.on);

  final bool on;

  @override
  List<Object?> get props => <Object?>[on];
}

/// Dispatched when active equipment profile is selected.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:648.
final class SettingsActiveEquipChanged extends SettingsEvent {
  const SettingsActiveEquipChanged(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Dispatched when an equipment profile is created or edited.
/// Mirrors `../openGym/frontend/src/sheets.jsx`:1076-1116 EquipmentProfileSheet.
final class SettingsEquipProfileSaved extends SettingsEvent {
  const SettingsEquipProfileSaved({
    this.id,
    required this.name,
    required this.equipment,
  });

  final String? id;
  final String name;
  final List<String> equipment;

  @override
  List<Object?> get props => <Object?>[id, name, equipment];
}

/// Dispatched when an equipment profile is deleted.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:636-644.
final class SettingsEquipProfileDeleted extends SettingsEvent {
  const SettingsEquipProfileDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// Dispatched when user confirms full data reset.
/// Mirrors `../openGym/frontend/src/views/Settings.jsx`:161-184 resetEverything.
final class SettingsResetConfirmed extends SettingsEvent {
  const SettingsResetConfirmed();
}
