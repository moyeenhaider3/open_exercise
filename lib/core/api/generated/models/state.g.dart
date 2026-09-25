// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

State _$StateFromJson(Map<String, dynamic> json) => State(
  privateTs: json['_ts'] as num?,
  privateRev: (json['_rev'] as num?)?.toInt(),
  unit: json['unit'] == null
      ? null
      : StateUnitUnit.fromJson(json['unit'] as String),
  lang: json['lang'] as String?,
  theme: json['theme'] as String?,
  accent: json['accent'] as String?,
  workouts: (json['workouts'] as List<dynamic>?)
      ?.map((e) => Workout.fromJson(e as Map<String, dynamic>))
      .toList(),
  routines: (json['routines'] as List<dynamic>?)
      ?.map((e) => Routine.fromJson(e as Map<String, dynamic>))
      .toList(),
  week: (json['week'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  dayPlan: (json['dayPlan'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  bodyweight: (json['bodyweight'] as List<dynamic>?)
      ?.map((e) => BodyweightEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  customEx: json['customEx'] as List<dynamic>?,
  exWeights: json['exWeights'] as Map<String, dynamic>?,
  reminder: json['reminder'] == null
      ? null
      : StateReminder.fromJson(json['reminder'] as Map<String, dynamic>),
  restSec: json['restSec'] as num?,
  effort: json['effort'] == null
      ? null
      : StateEffortEffort.fromJson(json['effort'] as String),
  equipProfiles: json['equipProfiles'] as List<dynamic>?,
  settings: json['settings'],
);

Map<String, dynamic> _$StateToJson(State instance) => <String, dynamic>{
  '_ts': instance.privateTs,
  '_rev': instance.privateRev,
  'unit': instance.unit,
  'lang': instance.lang,
  'theme': instance.theme,
  'accent': instance.accent,
  'workouts': instance.workouts,
  'routines': instance.routines,
  'week': instance.week,
  'dayPlan': instance.dayPlan,
  'bodyweight': instance.bodyweight,
  'customEx': instance.customEx,
  'exWeights': instance.exWeights,
  'reminder': instance.reminder,
  'restSec': instance.restSec,
  'effort': instance.effort,
  'equipProfiles': instance.equipProfiles,
  'settings': instance.settings,
};
