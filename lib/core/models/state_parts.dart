// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'json_passthrough.dart';

/// Daily "workout planned today" push settings (`../openGym/frontend/src/store/useStore.js`
/// DEF.reminder, line ~59; `../openGym/api/openapi.yaml` State.reminder). `tz` is `null` until
/// the user picks one -- it is kept as an explicit `null` on output, not dropped, exactly like
/// the JSON it was read from.
class Reminder extends Equatable {
  const Reminder({this.on, this.time, this.tz, this.extra = const <String, Object?>{}});

  final bool? on;
  final String? time;
  final String? tz;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'on', 'time', 'tz'};

  factory Reminder.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return Reminder(
      on: reader.boolean('on'),
      time: reader.string('time'),
      tz: reader.string('tz'),
      extra: reader.extra,
    );
  }

  // Note: an explicit `tz: null` on input is preserved on output without any special-casing
  // here. `JsonReader.string` demotes a present-but-null value into `extra` (see
  // json_passthrough.dart), so `extra` already carries `'tz': null` in that case and `emit`
  // reproduces it; only a genuinely *absent* `tz` key stays absent.
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'on': on, 'time': time, 'tz': tz});

  @override
  List<Object?> get props => <Object?>[on, time, tz, extra];
}

/// Which optional control groups the active-workout screen shows besides the sets themselves
/// (`../openGym/frontend/src/lib/workout-controls.js` `WC_DEFAULT`). One typed field per
/// `WC_DEFAULT` key, named identically. Any future control flag added to `WC_DEFAULT` before
/// this model is updated survives untouched in [extra].
class WorkoutControls extends Equatable {
  const WorkoutControls({
    this.steppers,
    this.setShortcuts,
    this.pairButtons,
    this.exerciseButtons,
    this.extra = const <String, Object?>{},
  });

  final bool? steppers;
  final bool? setShortcuts;
  final bool? pairButtons;
  final bool? exerciseButtons;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{
    'steppers', 'setShortcuts', 'pairButtons', 'exerciseButtons',
  };

  factory WorkoutControls.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return WorkoutControls(
      steppers: reader.boolean('steppers'),
      setShortcuts: reader.boolean('setShortcuts'),
      pairButtons: reader.boolean('pairButtons'),
      exerciseButtons: reader.boolean('exerciseButtons'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'steppers': steppers,
        'setShortcuts': setShortcuts,
        'pairButtons': pairButtons,
        'exerciseButtons': exerciseButtons,
      });

  @override
  List<Object?> get props =>
      <Object?>[steppers, setShortcuts, pairButtons, exerciseButtons, extra];
}

/// An equipment profile (`../openGym/frontend/src/lib/equipment.js` `newProfile`) -- a named set
/// of equipment (e.g. "Home" vs "Gym") used to filter the exercise library and picker.
class EquipProfile extends Equatable {
  const EquipProfile({
    this.id,
    this.name,
    this.equipment,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final String? name;
  final List<String>? equipment;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'name', 'equipment'};

  factory EquipProfile.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return EquipProfile(
      id: reader.string('id'),
      name: reader.string('name'),
      equipment: reader.stringList('equipment'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'name': name,
        'equipment': equipment,
      });

  EquipProfile copyWith({
    String? id,
    String? name,
    List<String>? equipment,
    Map<String, Object?>? extra,
  }) {
    return EquipProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      equipment: equipment ?? this.equipment,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, equipment, extra];
}

/// A gym check-in card (`../openGym/frontend/src/store/useStore.js` DEF.gymCards comment,
/// line ~73): a membership code shown as a QR/barcode at the gym's turnstile. Only the code's
/// value is ever kept -- the image is regenerated from it every time it's shown.
class GymCard extends Equatable {
  const GymCard({
    this.id,
    this.label,
    this.value,
    this.fmt,
    this.extra = const <String, Object?>{},
  });

  final String? id;
  final String? label;
  final String? value;
  final String? fmt;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'label', 'value', 'fmt'};

  factory GymCard.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return GymCard(
      id: reader.string('id'),
      label: reader.string('label'),
      value: reader.string('value'),
      fmt: reader.string('fmt'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'id': id,
        'label': label,
        'value': value,
        'fmt': fmt,
      });

  GymCard copyWith({
    String? id,
    String? label,
    String? value,
    String? fmt,
    Map<String, Object?>? extra,
  }) {
    return GymCard(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      fmt: fmt ?? this.fmt,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, label, value, fmt, extra];
}

/// A user-created exercise (`../openGym/api/openapi.yaml` State.customEx: "id, name,
/// muscles..."). Only `id` and `name` are modelled here -- the exercise catalogue fields
/// (`muscles`, `eq`, etc.) belong to the Phase 3 exercise catalogue and stay in [extra] until
/// then.
class CustomExercise extends Equatable {
  const CustomExercise({this.id, this.name, this.extra = const <String, Object?>{}});

  final String? id;
  final String? name;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'id', 'name'};

  factory CustomExercise.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return CustomExercise(id: reader.string('id'), name: reader.string('name'), extra: reader.extra);
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'id': id, 'name': name});

  @override
  List<Object?> get props => <Object?>[id, name, extra];
}

/// Per-exercise last/best weight memory (`../openGym/api/openapi.yaml` State.exWeights:
/// "exercise id -> {w, d}"). Values live inside `GymState.exWeights`, keyed by exercise id.
class ExWeight extends Equatable {
  const ExWeight({this.w, this.d, this.extra = const <String, Object?>{}});

  final num? w;
  final String? d;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'w', 'd'};

  factory ExWeight.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return ExWeight(w: reader.number('w'), d: reader.string('d'), extra: reader.extra);
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'w': w, 'd': d});

  @override
  List<Object?> get props => <Object?>[w, d, extra];
}
