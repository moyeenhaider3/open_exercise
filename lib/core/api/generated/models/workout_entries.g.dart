// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutEntries _$WorkoutEntriesFromJson(Map<String, dynamic> json) =>
    WorkoutEntries(
      id: json['id'] as String?,
      topW: json['topW'] as num?,
      sets: (json['sets'] as List<dynamic>?)
          ?.map((e) => WorkoutEntriesSets.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutEntriesToJson(WorkoutEntries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topW': instance.topW,
      'sets': instance.sets,
    };
