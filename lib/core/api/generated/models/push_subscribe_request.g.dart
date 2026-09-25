// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_subscribe_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushSubscribeRequest _$PushSubscribeRequestFromJson(
  Map<String, dynamic> json,
) => PushSubscribeRequest(
  subscription: PushSubscription.fromJson(
    json['subscription'] as Map<String, dynamic>,
  ),
  deviceId: json['deviceId'] as String?,
);

Map<String, dynamic> _$PushSubscribeRequestToJson(
  PushSubscribeRequest instance,
) => <String, dynamic>{
  'subscription': instance.subscription,
  'deviceId': instance.deviceId,
};
