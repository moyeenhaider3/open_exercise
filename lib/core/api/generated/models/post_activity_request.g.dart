// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_activity_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostActivityRequest _$PostActivityRequestFromJson(Map<String, dynamic> json) =>
    PostActivityRequest(
      active: json['active'] as bool?,
      name: json['name'] as String?,
      exIdx: (json['exIdx'] as num?)?.toInt(),
      exTotal: (json['exTotal'] as num?)?.toInt(),
      setsDone: (json['setsDone'] as num?)?.toInt(),
      setsTotal: (json['setsTotal'] as num?)?.toInt(),
      startedAt: json['startedAt'] as num?,
    );

Map<String, dynamic> _$PostActivityRequestToJson(
  PostActivityRequest instance,
) => <String, dynamic>{
  'active': instance.active,
  'name': instance.name,
  'exIdx': instance.exIdx,
  'exTotal': instance.exTotal,
  'setsDone': instance.setsDone,
  'setsTotal': instance.setsTotal,
  'startedAt': instance.startedAt,
};
