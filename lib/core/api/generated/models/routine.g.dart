// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Routine _$RoutineFromJson(Map<String, dynamic> json) => Routine(
  id: json['id'] as String?,
  name: json['name'] as String?,
  emoji: json['emoji'] as String?,
  ex: json['ex'] as List<dynamic>?,
);

Map<String, dynamic> _$RoutineToJson(Routine instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'ex': instance.ex,
};
