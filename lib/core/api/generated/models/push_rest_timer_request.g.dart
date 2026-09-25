// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_rest_timer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushRestTimerRequest _$PushRestTimerRequestFromJson(
  Map<String, dynamic> json,
) => PushRestTimerRequest(
  seconds: json['seconds'] as num,
  deviceId: json['deviceId'] as String?,
);

Map<String, dynamic> _$PushRestTimerRequestToJson(
  PushRestTimerRequest instance,
) => <String, dynamic>{
  'seconds': instance.seconds,
  'deviceId': instance.deviceId,
};
