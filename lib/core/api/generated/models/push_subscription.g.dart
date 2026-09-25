// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushSubscription _$PushSubscriptionFromJson(Map<String, dynamic> json) =>
    PushSubscription(
      endpoint: json['endpoint'] as String,
      keys: PushSubscriptionKeys.fromJson(json['keys'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PushSubscriptionToJson(PushSubscription instance) =>
    <String, dynamic>{'endpoint': instance.endpoint, 'keys': instance.keys};
