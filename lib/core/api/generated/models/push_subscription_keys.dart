// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_subscription_keys.g.dart';

@JsonSerializable()
class PushSubscriptionKeys {
  const PushSubscriptionKeys({required this.p256dh, required this.auth});

  factory PushSubscriptionKeys.fromJson(Map<String, Object?> json) =>
      _$PushSubscriptionKeysFromJson(json);

  final String p256dh;
  final String auth;

  Map<String, Object?> toJson() => _$PushSubscriptionKeysToJson(this);
}
