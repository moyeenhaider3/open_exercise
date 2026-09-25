// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'push_subscription_keys.dart';

part 'push_subscription.g.dart';

/// The browser's PushSubscription.toJSON() — only these fields are stored.
@JsonSerializable()
class PushSubscription {
  const PushSubscription({required this.endpoint, required this.keys});

  factory PushSubscription.fromJson(Map<String, Object?> json) =>
      _$PushSubscriptionFromJson(json);

  /// Public https:// push-service URL.
  final String endpoint;
  final PushSubscriptionKeys keys;

  Map<String, Object?> toJson() => _$PushSubscriptionToJson(this);
}
