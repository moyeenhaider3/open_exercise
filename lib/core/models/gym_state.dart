// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'bodyweight_entry.dart';
import 'default_state.dart';
import 'json_passthrough.dart';
import 'routine.dart';
import 'state_parts.dart';
import 'workout.dart';

/// Reads a JSON object field as `Map<String, String>`, mirroring [JsonReader]'s
/// whole-value-or-demote rule one level down: a present map with every value a `String` is
/// typed; a present map with any other value type is demoted whole (unparsed) into [demotions]
/// under [key], exactly like an unknown/wrong-typed scalar field.
Map<String, String>? _stringValueMap(
  JsonReader reader,
  String key,
  Map<String, Object?> demotions,
) {
  final Map<String, Object?>? raw = reader.map(key);
  if (raw == null) return null;
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    if (entry.value case final String s) {
      result[entry.key] = s;
    } else {
      demotions[key] = raw;
      return null;
    }
  }
  return result;
}

/// Reads a JSON object field as `Map<String, Object>`, where every value is either a `String` or
/// a `List<String>` (openGym stores both: old profiles a single id, current openGym writes
/// lists). A present map matching that rule is typed; a present map with any other value shape
/// is demoted whole (unparsed) into [demotions] under [key], exactly like an unknown/wrong-typed
/// scalar field.
Map<String, Object>? _weekMap(
  JsonReader reader,
  String key,
  Map<String, Object?> demotions,
) {
  final Map<String, Object?>? raw = reader.map(key);
  if (raw == null) return null;
  final Map<String, Object> result = <String, Object>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    final Object? val = entry.value;
    if (val case final String s) {
      result[entry.key] = s;
    } else if (val case final List<Object?> l) {
      final List<String> stringList = <String>[];
      for (final Object? item in l) {
        if (item case final String s) {
          stringList.add(s);
        } else {
          demotions[key] = raw;
          return null;
        }
      }
      result[entry.key] = stringList;
    } else {
      demotions[key] = raw;
      return null;
    }
  }
  return result;
}

/// As [_stringValueMap], but for `Map<String, num>` (`barWeights`).
Map<String, num>? _numValueMap(
  JsonReader reader,
  String key,
  Map<String, Object?> demotions,
) {
  final Map<String, Object?>? raw = reader.map(key);
  if (raw == null) return null;
  final Map<String, num> result = <String, num>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    if (entry.value case final num n) {
      result[entry.key] = n;
    } else {
      demotions[key] = raw;
      return null;
    }
  }
  return result;
}

/// As [_stringValueMap], but for `Map<String, ExWeight>` (`exWeights`): every value must itself
/// be an object, otherwise the whole map is demoted unparsed.
Map<String, ExWeight>? _exWeightMap(
  JsonReader reader,
  String key,
  Map<String, Object?> demotions,
) {
  final Map<String, Object?>? raw = reader.map(key);
  if (raw == null) return null;
  final Map<String, ExWeight> result = <String, ExWeight>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    if (entry.value case final Map<String, Object?> m) {
      result[entry.key] = ExWeight.fromJson(m);
    } else {
      demotions[key] = raw;
      return null;
    }
  }
  return result;
}

/// The whole user profile (`../openGym/frontend/src/store/useStore.js` `DEF`;
/// `../openGym/api/openapi.yaml` State schema). One typed nullable field per `DEF` key, plus
/// sync metadata (`ts`/`_ts`, `rev`/`_rev`). Holds every later phase's persisted state -- Blocs,
/// the JS bridge and sync all read and write through this model. No JS-domain math (1RM,
/// volume, progression) lives here -- that stays in JS, per JS-04; this model only carries data.
///
/// `GymState.fromJson` first overlays the input onto [kDefaultState] exactly like openGym's own
/// `loadState()` (`Object.assign(clone(DEF), loaded)`), so an old profile missing a newer key
/// gains that key's default -- and `toJson()` round-trips whatever it was given (including any
/// key this model doesn't know about, in [extra]) without loss.
class GymState extends Equatable {
  const GymState({
    this.unit,
    this.restSec,
    this.restPauseSec,
    this.sound,
    this.soundOnSilent,
    this.timerFlash,
    this.keepAwake,
    this.lang,
    this.theme,
    this.accent,
    this.body,
    this.targetW,
    this.bodyweight,
    this.routines,
    this.week,
    this.dayPlan,
    this.exWeights,
    this.workouts,
    this.active,
    this.customEx,
    this.gifSize,
    this.workoutView,
    this.wc,
    this.reminder,
    this.effort,
    this.autoBackup,
    this.equipProfiles,
    this.activeEquipId,
    this.equipFilterOn,
    this.exNotes,
    this.favEx,
    this.weekStart,
    this.wdec,
    this.barWeights,
    this.gymCards,
    this.lastGymCardId,
    this.checkIn,
    this.weighIn,
    this.ts,
    this.rev,
    this.extra = const <String, Object?>{},
  });

  final String? unit;
  final num? restSec;
  final num? restPauseSec;
  final bool? sound;
  final bool? soundOnSilent;
  final bool? timerFlash;
  final bool? keepAwake;
  final String? lang;
  final String? theme;
  final String? accent;
  final String? body;
  final num? targetW;
  final List<BodyweightEntry>? bodyweight;
  final List<Routine>? routines;
  final Map<String, Object>? week;
  final Map<String, String>? dayPlan;
  final Map<String, ExWeight>? exWeights;
  final List<Workout>? workouts;
  final Workout? active;
  final List<CustomExercise>? customEx;
  final String? gifSize;
  final String? workoutView;
  final WorkoutControls? wc;
  final Reminder? reminder;
  final String? effort;
  final bool? autoBackup;
  final List<EquipProfile>? equipProfiles;
  final String? activeEquipId;
  final bool? equipFilterOn;
  final Map<String, String>? exNotes;
  final List<String>? favEx;
  final num? weekStart;
  final num? wdec;
  final Map<String, num>? barWeights;
  final List<GymCard>? gymCards;
  final String? lastGymCardId;
  final bool? checkIn;
  final bool? weighIn;
  /// Client-set last-write timestamp (ms since epoch); JSON key `_ts`.
  final num? ts;
  /// Server-set revision, incremented on every accepted write; JSON key `_rev`.
  final int? rev;
  final Map<String, Object?> extra;

  /// `useStore.js` DEF defaults, exposed as constants for callers that need the bare value
  /// without constructing a whole [GymState] (e.g. a theme picker's "reset" option).
  static const String defaultTheme = 'dark';
  static const String defaultAccent = 'lime';

  static const Set<String> _known = <String>{
    'unit', 'restSec', 'restPauseSec', 'sound', 'soundOnSilent', 'timerFlash', 'keepAwake',
    'lang', 'theme', 'accent', 'body', 'targetW', 'bodyweight', 'routines', 'week', 'dayPlan',
    'exWeights', 'workouts', 'active', 'customEx', 'gifSize', 'workoutView', 'wc', 'reminder',
    'effort', 'autoBackup', 'equipProfiles', 'activeEquipId', 'equipFilterOn', 'exNotes', 'favEx',
    'weekStart', 'wdec', 'barWeights', 'gymCards', 'lastGymCardId', 'checkIn', 'weighIn',
    '_ts', '_rev',
  };
  static const Set<String> knownKeys = _known;

  /// Overlays [json] onto [kDefaultState] (exactly like openGym's `loadState`) and parses the
  /// result. Every DEF key an older/partial profile is missing is filled in from the default;
  /// every key this model doesn't know about (including future top-level keys) survives in
  /// [extra] unchanged.
  factory GymState.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> merged = overlayOnDefaults(json);
    final JsonReader reader = JsonReader(merged, known: _known);
    final Map<String, Object?> demotions = <String, Object?>{};

    final Map<String, Object>? week = _weekMap(reader, 'week', demotions);
    final Map<String, String>? dayPlan = _stringValueMap(reader, 'dayPlan', demotions);
    final Map<String, String>? exNotes = _stringValueMap(reader, 'exNotes', demotions);
    final Map<String, num>? barWeights = _numValueMap(reader, 'barWeights', demotions);
    final Map<String, ExWeight>? exWeights = _exWeightMap(reader, 'exWeights', demotions);

    final Map<String, Object?>? wcMap = reader.map('wc');
    final Map<String, Object?>? reminderMap = reader.map('reminder');
    final Map<String, Object?>? activeMap = reader.map('active');

    return GymState(
      unit: reader.string('unit'),
      restSec: reader.number('restSec'),
      restPauseSec: reader.number('restPauseSec'),
      sound: reader.boolean('sound'),
      soundOnSilent: reader.boolean('soundOnSilent'),
      timerFlash: reader.boolean('timerFlash'),
      keepAwake: reader.boolean('keepAwake'),
      lang: reader.string('lang'),
      theme: reader.string('theme'),
      accent: reader.string('accent'),
      body: reader.string('body'),
      targetW: reader.number('targetW'),
      bodyweight: reader.objectList<BodyweightEntry>('bodyweight', BodyweightEntry.fromJson),
      routines: reader.objectList<Routine>('routines', Routine.fromJson),
      week: week,
      dayPlan: dayPlan,
      exWeights: exWeights,
      workouts: reader.objectList<Workout>('workouts', Workout.fromJson),
      active: activeMap == null ? null : Workout.fromJson(activeMap),
      customEx: reader.objectList<CustomExercise>('customEx', CustomExercise.fromJson),
      gifSize: reader.string('gifSize'),
      workoutView: reader.string('workoutView'),
      wc: wcMap == null ? null : WorkoutControls.fromJson(wcMap),
      reminder: reminderMap == null ? null : Reminder.fromJson(reminderMap),
      effort: reader.string('effort'),
      autoBackup: reader.boolean('autoBackup'),
      equipProfiles: reader.objectList<EquipProfile>('equipProfiles', EquipProfile.fromJson),
      activeEquipId: reader.string('activeEquipId'),
      equipFilterOn: reader.boolean('equipFilterOn'),
      exNotes: exNotes,
      favEx: reader.stringList('favEx'),
      weekStart: reader.number('weekStart'),
      wdec: reader.number('wdec'),
      barWeights: barWeights,
      gymCards: reader.objectList<GymCard>('gymCards', GymCard.fromJson),
      lastGymCardId: reader.string('lastGymCardId'),
      checkIn: reader.boolean('checkIn'),
      weighIn: reader.boolean('weighIn'),
      ts: reader.number('_ts'),
      rev: reader.integer('_rev'),
      extra: <String, Object?>{...reader.extra, ...demotions},
    );
  }

  /// `GymState.fromJson(const {})` -- every DEF key at its default value.
  factory GymState.defaults() => GymState.fromJson(const <String, Object?>{});

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'unit': unit,
        'restSec': restSec,
        'restPauseSec': restPauseSec,
        'sound': sound,
        'soundOnSilent': soundOnSilent,
        'timerFlash': timerFlash,
        'keepAwake': keepAwake,
        'lang': lang,
        'theme': theme,
        'accent': accent,
        'body': body,
        'targetW': targetW,
        'bodyweight': bodyweight?.map((BodyweightEntry b) => b.toJson()).toList(),
        'routines': routines?.map((Routine r) => r.toJson()).toList(),
        'week': week,
        'dayPlan': dayPlan,
        'exWeights': exWeights?.map((String k, ExWeight v) => MapEntry<String, Object?>(k, v.toJson())),
        'workouts': workouts?.map((Workout w) => w.toJson()).toList(),
        'active': active?.toJson(),
        'customEx': customEx?.map((CustomExercise c) => c.toJson()).toList(),
        'gifSize': gifSize,
        'workoutView': workoutView,
        'wc': wc?.toJson(),
        'reminder': reminder?.toJson(),
        'effort': effort,
        'autoBackup': autoBackup,
        'equipProfiles': equipProfiles?.map((EquipProfile e) => e.toJson()).toList(),
        'activeEquipId': activeEquipId,
        'equipFilterOn': equipFilterOn,
        'exNotes': exNotes,
        'favEx': favEx,
        'weekStart': weekStart,
        'wdec': wdec,
        'barWeights': barWeights,
        'gymCards': gymCards?.map((GymCard g) => g.toJson()).toList(),
        'lastGymCardId': lastGymCardId,
        'checkIn': checkIn,
        'weighIn': weighIn,
        '_ts': ts,
        '_rev': rev,
      });

  /// Returns a copy with the given fields replaced. Every field parameter defaults to a private
  /// sentinel, so passing `null` explicitly *clears* the field (openGym writes explicit nulls,
  /// e.g. `active = null` when a workout ends): the typed value becomes null and `extra` gets
  /// `key: null`, so [toJson] emits an explicit null. Passing a non-null value sets the typed
  /// field and drops any stale entry for that key from `extra` (left over from a null or
  /// wrong-typed value demoted by `JsonReader`). Omitted fields are kept as they are.
  /// [extra], if given, replaces the base `extra` map before those per-key adjustments.
  GymState copyWith({
    Object? unit = _unset,
    Object? restSec = _unset,
    Object? restPauseSec = _unset,
    Object? sound = _unset,
    Object? soundOnSilent = _unset,
    Object? timerFlash = _unset,
    Object? keepAwake = _unset,
    Object? lang = _unset,
    Object? theme = _unset,
    Object? accent = _unset,
    Object? body = _unset,
    Object? targetW = _unset,
    Object? bodyweight = _unset,
    Object? routines = _unset,
    Object? week = _unset,
    Object? dayPlan = _unset,
    Object? exWeights = _unset,
    Object? workouts = _unset,
    Object? active = _unset,
    Object? customEx = _unset,
    Object? gifSize = _unset,
    Object? workoutView = _unset,
    Object? wc = _unset,
    Object? reminder = _unset,
    Object? effort = _unset,
    Object? autoBackup = _unset,
    Object? equipProfiles = _unset,
    Object? activeEquipId = _unset,
    Object? equipFilterOn = _unset,
    Object? exNotes = _unset,
    Object? favEx = _unset,
    Object? weekStart = _unset,
    Object? wdec = _unset,
    Object? barWeights = _unset,
    Object? gymCards = _unset,
    Object? lastGymCardId = _unset,
    Object? checkIn = _unset,
    Object? weighIn = _unset,
    Object? ts = _unset,
    Object? rev = _unset,
    Map<String, Object?>? extra,
  }) {
    final Map<String, Object?> nextExtra = <String, Object?>{...(extra ?? this.extra)};
    T? pick<T>(Object? value, T? current, String key) {
      if (identical(value, _unset)) return current;
      if (value == null) {
        nextExtra[key] = null;
        return null;
      }
      nextExtra.remove(key);
      return value as T;
    }

    return GymState(
      unit: pick<String>(unit, this.unit, 'unit'),
      restSec: pick<num>(restSec, this.restSec, 'restSec'),
      restPauseSec: pick<num>(restPauseSec, this.restPauseSec, 'restPauseSec'),
      sound: pick<bool>(sound, this.sound, 'sound'),
      soundOnSilent: pick<bool>(soundOnSilent, this.soundOnSilent, 'soundOnSilent'),
      timerFlash: pick<bool>(timerFlash, this.timerFlash, 'timerFlash'),
      keepAwake: pick<bool>(keepAwake, this.keepAwake, 'keepAwake'),
      lang: pick<String>(lang, this.lang, 'lang'),
      theme: pick<String>(theme, this.theme, 'theme'),
      accent: pick<String>(accent, this.accent, 'accent'),
      body: pick<String>(body, this.body, 'body'),
      targetW: pick<num>(targetW, this.targetW, 'targetW'),
      bodyweight: pick<List<BodyweightEntry>>(bodyweight, this.bodyweight, 'bodyweight'),
      routines: pick<List<Routine>>(routines, this.routines, 'routines'),
      week: pick<Map<String, Object>>(week is Map ? Map<String, Object>.from(week) : week, this.week, 'week'),
      dayPlan: pick<Map<String, String>>(dayPlan, this.dayPlan, 'dayPlan'),
      exWeights: pick<Map<String, ExWeight>>(exWeights, this.exWeights, 'exWeights'),
      workouts: pick<List<Workout>>(workouts, this.workouts, 'workouts'),
      active: pick<Workout>(active, this.active, 'active'),
      customEx: pick<List<CustomExercise>>(customEx, this.customEx, 'customEx'),
      gifSize: pick<String>(gifSize, this.gifSize, 'gifSize'),
      workoutView: pick<String>(workoutView, this.workoutView, 'workoutView'),
      wc: pick<WorkoutControls>(wc, this.wc, 'wc'),
      reminder: pick<Reminder>(reminder, this.reminder, 'reminder'),
      effort: pick<String>(effort, this.effort, 'effort'),
      autoBackup: pick<bool>(autoBackup, this.autoBackup, 'autoBackup'),
      equipProfiles: pick<List<EquipProfile>>(equipProfiles, this.equipProfiles, 'equipProfiles'),
      activeEquipId: pick<String>(activeEquipId, this.activeEquipId, 'activeEquipId'),
      equipFilterOn: pick<bool>(equipFilterOn, this.equipFilterOn, 'equipFilterOn'),
      exNotes: pick<Map<String, String>>(exNotes, this.exNotes, 'exNotes'),
      favEx: pick<List<String>>(favEx, this.favEx, 'favEx'),
      weekStart: pick<num>(weekStart, this.weekStart, 'weekStart'),
      wdec: pick<num>(wdec, this.wdec, 'wdec'),
      barWeights: pick<Map<String, num>>(barWeights, this.barWeights, 'barWeights'),
      gymCards: pick<List<GymCard>>(gymCards, this.gymCards, 'gymCards'),
      lastGymCardId: pick<String>(lastGymCardId, this.lastGymCardId, 'lastGymCardId'),
      checkIn: pick<bool>(checkIn, this.checkIn, 'checkIn'),
      weighIn: pick<bool>(weighIn, this.weighIn, 'weighIn'),
      ts: pick<num>(ts, this.ts, '_ts'),
      rev: pick<int>(rev, this.rev, '_rev'),
      extra: Map<String, Object?>.unmodifiable(nextExtra),
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => <Object?>[
        unit,
        restSec,
        restPauseSec,
        sound,
        soundOnSilent,
        timerFlash,
        keepAwake,
        lang,
        theme,
        accent,
        body,
        targetW,
        bodyweight,
        routines,
        week,
        dayPlan,
        exWeights,
        workouts,
        active,
        customEx,
        gifSize,
        workoutView,
        wc,
        reminder,
        effort,
        autoBackup,
        equipProfiles,
        activeEquipId,
        equipFilterOn,
        exNotes,
        favEx,
        weekStart,
        wdec,
        barWeights,
        gymCards,
        lastGymCardId,
        checkIn,
        weighIn,
        ts,
        rev,
        extra,
      ];
}
