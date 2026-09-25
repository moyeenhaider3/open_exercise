// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_entries_sets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutEntriesSets _$WorkoutEntriesSetsFromJson(Map<String, dynamic> json) =>
    WorkoutEntriesSets(
      w: json['w'] as num?,
      r: json['r'] as num?,
      done: json['done'] as bool?,
      rir: json['rir'] as num?,
      rpe: json['rpe'] as num?,
    );

Map<String, dynamic> _$WorkoutEntriesSetsToJson(WorkoutEntriesSets instance) =>
    <String, dynamic>{
      'w': instance.w,
      'r': instance.r,
      'done': instance.done,
      'rir': instance.rir,
      'rpe': instance.rpe,
    };
