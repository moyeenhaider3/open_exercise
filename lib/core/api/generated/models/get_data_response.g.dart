// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDataResponse _$GetDataResponseFromJson(Map<String, dynamic> json) =>
    GetDataResponse(
      state: json['state'] == null
          ? null
          : State.fromJson(json['state'] as Map<String, dynamic>),
      rev: (json['rev'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GetDataResponseToJson(GetDataResponse instance) =>
    <String, dynamic>{'state': instance.state, 'rev': instance.rev};
