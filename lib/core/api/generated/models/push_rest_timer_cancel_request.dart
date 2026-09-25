// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_rest_timer_cancel_request.g.dart';

@JsonSerializable()
class PushRestTimerCancelRequest {
  const PushRestTimerCancelRequest({this.deviceId});

  factory PushRestTimerCancelRequest.fromJson(Map<String, Object?> json) =>
      _$PushRestTimerCancelRequestFromJson(json);

  final String? deviceId;

  Map<String, Object?> toJson() => _$PushRestTimerCancelRequestToJson(this);
}
