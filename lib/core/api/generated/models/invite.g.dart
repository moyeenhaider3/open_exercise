// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) => Invite(
  code: json['code'] as String?,
  note: json['note'] as String?,
  createdBy: json['createdBy'] as String?,
  created: json['created'] as String?,
  usedBy: json['usedBy'] as String?,
  usedAt: json['usedAt'] as String?,
  usedByName: json['usedByName'] as String?,
);

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'code': instance.code,
  'note': instance.note,
  'createdBy': instance.createdBy,
  'created': instance.created,
  'usedBy': instance.usedBy,
  'usedAt': instance.usedAt,
  'usedByName': instance.usedByName,
};
