// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionUser _$SessionUserFromJson(Map<String, dynamic> json) => SessionUser(
  id: json['id'] as String?,
  name: json['name'] as String?,
  admin: json['admin'] as bool?,
);

Map<String, dynamic> _$SessionUserToJson(SessionUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'admin': instance.admin,
    };
