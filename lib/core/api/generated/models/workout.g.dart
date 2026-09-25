// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
  id: json['id'] as String?,
  d: json['d'] == null ? null : DateTime.parse(json['d'] as String),
  start: json['start'] as num?,
  end: json['end'] as num?,
  routineId: json['routineId'] as String?,
  name: json['name'] as String?,
  bw: json['bw'] as num?,
  vol: json['vol'] as num?,
  prs: (json['prs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  entries: (json['entries'] as List<dynamic>?)
      ?.map((e) => WorkoutEntries.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'id': instance.id,
  'd': instance.d?.toIso8601String(),
  'start': instance.start,
  'end': instance.end,
  'routineId': instance.routineId,
  'name': instance.name,
  'bw': instance.bw,
  'vol': instance.vol,
  'prs': instance.prs,
  'entries': instance.entries,
};
