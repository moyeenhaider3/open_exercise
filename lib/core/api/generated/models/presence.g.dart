// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Presence _$PresenceFromJson(Map<String, dynamic> json) => Presence(
  name: json['name'] as String?,
  exIdx: (json['exIdx'] as num?)?.toInt(),
  exTotal: (json['exTotal'] as num?)?.toInt(),
  setsDone: (json['setsDone'] as num?)?.toInt(),
  setsTotal: (json['setsTotal'] as num?)?.toInt(),
  startedAt: json['startedAt'] as num?,
  updatedAt: json['updatedAt'] as num?,
);

Map<String, dynamic> _$PresenceToJson(Presence instance) => <String, dynamic>{
  'name': instance.name,
  'exIdx': instance.exIdx,
  'exTotal': instance.exTotal,
  'setsDone': instance.setsDone,
  'setsTotal': instance.setsTotal,
  'startedAt': instance.startedAt,
  'updatedAt': instance.updatedAt,
};
