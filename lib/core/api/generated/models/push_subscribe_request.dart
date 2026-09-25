// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'push_subscription.dart';

part 'push_subscribe_request.g.dart';

@JsonSerializable()
class PushSubscribeRequest {
  const PushSubscribeRequest({required this.subscription, this.deviceId});

  factory PushSubscribeRequest.fromJson(Map<String, Object?> json) =>
      _$PushSubscribeRequestFromJson(json);

  final PushSubscription subscription;

  /// A token the browser made up for itself (stored in its localStorage), so rest-timer pushes can be aimed at the device that started the rest. Optional; anything that is not a short token is ignored.
  final String? deviceId;

  Map<String, Object?> toJson() => _$PushSubscribeRequestToJson(this);
}
