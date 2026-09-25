// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_data_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutDataRequest _$PutDataRequestFromJson(Map<String, dynamic> json) =>
    PutDataRequest(
      state: State.fromJson(json['state'] as Map<String, dynamic>),
      baseRev: (json['baseRev'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PutDataRequestToJson(PutDataRequest instance) =>
    <String, dynamic>{'state': instance.state, 'baseRev': instance.baseRev};
