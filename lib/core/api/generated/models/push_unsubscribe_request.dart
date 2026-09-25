// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_unsubscribe_request.g.dart';

@JsonSerializable()
class PushUnsubscribeRequest {
  const PushUnsubscribeRequest({required this.endpoint});

  factory PushUnsubscribeRequest.fromJson(Map<String, Object?> json) =>
      _$PushUnsubscribeRequestFromJson(json);

  final String endpoint;

  Map<String, Object?> toJson() => _$PushUnsubscribeRequestToJson(this);
}
