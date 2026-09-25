// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutDataResponse _$PutDataResponseFromJson(Map<String, dynamic> json) =>
    PutDataResponse(
      ok: json['ok'] as bool?,
      ts: json['ts'] as num?,
      rev: (json['rev'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PutDataResponseToJson(PutDataResponse instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'ts': instance.ts,
      'rev': instance.rev,
    };
