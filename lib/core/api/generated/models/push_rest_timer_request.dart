// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_rest_timer_request.g.dart';

@JsonSerializable()
class PushRestTimerRequest {
  const PushRestTimerRequest({required this.seconds, this.deviceId});

  factory PushRestTimerRequest.fromJson(Map<String, Object?> json) =>
      _$PushRestTimerRequestFromJson(json);

  final num seconds;

  /// The browser's own token, see `POST /api/push/subscribe`. Optional.
  final String? deviceId;

  Map<String, Object?> toJson() => _$PushRestTimerRequestToJson(this);
}
