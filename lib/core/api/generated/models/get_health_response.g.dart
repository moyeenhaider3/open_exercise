// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_health_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetHealthResponse _$GetHealthResponseFromJson(Map<String, dynamic> json) =>
    GetHealthResponse(
      ok: json['ok'] as bool?,
      users: (json['users'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GetHealthResponseToJson(GetHealthResponse instance) =>
    <String, dynamic>{'ok': instance.ok, 'users': instance.users};
