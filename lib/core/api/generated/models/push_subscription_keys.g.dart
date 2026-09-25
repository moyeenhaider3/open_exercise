// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_subscription_keys.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushSubscriptionKeys _$PushSubscriptionKeysFromJson(
  Map<String, dynamic> json,
) => PushSubscriptionKeys(
  p256dh: json['p256dh'] as String,
  auth: json['auth'] as String,
);

Map<String, dynamic> _$PushSubscriptionKeysToJson(
  PushSubscriptionKeys instance,
) => <String, dynamic>{'p256dh': instance.p256dh, 'auth': instance.auth};
