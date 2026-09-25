// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_config_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetConfigResponse _$GetConfigResponseFromJson(Map<String, dynamic> json) =>
    GetConfigResponse(
      inviteOnly: json['invite_only'] as bool?,
      allowGuest: json['allow_guest'] as bool?,
    );

Map<String, dynamic> _$GetConfigResponseToJson(GetConfigResponse instance) =>
    <String, dynamic>{
      'invite_only': instance.inviteOnly,
      'allow_guest': instance.allowGuest,
    };
