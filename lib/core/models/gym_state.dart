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
  final Map<String, String>? week;
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

  /// Overlays [json] onto [kDefaultState] (exactly like openGym's `loadState`) and parses the
  /// result. Every DEF key an older/partial profile is missing is filled in from the default;
  /// every key this model doesn't know about (including future top-level keys) survives in
  /// [extra] unchanged.
  factory GymState.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> merged = overlayOnDefaults(json);
    final JsonReader reader = JsonReader(merged, known: _known);
    final Map<String, Object?> demotions = <String, Object?>{};

    final Map<String, String>? week = _stringValueMap(reader, 'week', demotions);
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

  GymState copyWith({
    String? unit,
    num? restSec,
    num? restPauseSec,
    bool? sound,
    bool? soundOnSilent,
    bool? timerFlash,
    bool? keepAwake,
    String? lang,
    String? theme,
    String? accent,
    String? body,
    num? targetW,
    List<BodyweightEntry>? bodyweight,
    List<Routine>? routines,
    Map<String, String>? week,
    Map<String, String>? dayPlan,
    Map<String, ExWeight>? exWeights,
    List<Workout>? workouts,
    Workout? active,
    List<CustomExercise>? customEx,
    String? gifSize,
    String? workoutView,
    WorkoutControls? wc,
    Reminder? reminder,
    String? effort,
    bool? autoBackup,
    List<EquipProfile>? equipProfiles,
    String? activeEquipId,
    bool? equipFilterOn,
    Map<String, String>? exNotes,
    List<String>? favEx,
    num? weekStart,
    num? wdec,
    Map<String, num>? barWeights,
    List<GymCard>? gymCards,
    String? lastGymCardId,
    bool? checkIn,
    bool? weighIn,
    num? ts,
    int? rev,
    Map<String, Object?>? extra,
  }) {
    return GymState(
      unit: unit ?? this.unit,
      restSec: restSec ?? this.restSec,
      restPauseSec: restPauseSec ?? this.restPauseSec,
      sound: sound ?? this.sound,
      soundOnSilent: soundOnSilent ?? this.soundOnSilent,
      timerFlash: timerFlash ?? this.timerFlash,
      keepAwake: keepAwake ?? this.keepAwake,
      lang: lang ?? this.lang,
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      body: body ?? this.body,
      targetW: targetW ?? this.targetW,
      bodyweight: bodyweight ?? this.bodyweight,
      routines: routines ?? this.routines,
      week: week ?? this.week,
      dayPlan: dayPlan ?? this.dayPlan,
      exWeights: exWeights ?? this.exWeights,
      workouts: workouts ?? this.workouts,
      active: active ?? this.active,
      customEx: customEx ?? this.customEx,
      gifSize: gifSize ?? this.gifSize,
      workoutView: workoutView ?? this.workoutView,
      wc: wc ?? this.wc,
      reminder: reminder ?? this.reminder,
      effort: effort ?? this.effort,
      autoBackup: autoBackup ?? this.autoBackup,
      equipProfiles: equipProfiles ?? this.equipProfiles,
      activeEquipId: activeEquipId ?? this.activeEquipId,
      equipFilterOn: equipFilterOn ?? this.equipFilterOn,
      exNotes: exNotes ?? this.exNotes,
      favEx: favEx ?? this.favEx,
      weekStart: weekStart ?? this.weekStart,
      wdec: wdec ?? this.wdec,
      barWeights: barWeights ?? this.barWeights,
      gymCards: gymCards ?? this.gymCards,
      lastGymCardId: lastGymCardId ?? this.lastGymCardId,
      checkIn: checkIn ?? this.checkIn,
      weighIn: weighIn ?? this.weighIn,
      ts: ts ?? this.ts,
      rev: rev ?? this.rev,
      extra: extra ?? this.extra,
    );
  }

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
