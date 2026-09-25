// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_status_response.g.dart';

@JsonSerializable()
class PushStatusResponse {
  const PushStatusResponse({this.subscribed});

  factory PushStatusResponse.fromJson(Map<String, Object?> json) =>
      _$PushStatusResponseFromJson(json);

  final bool? subscribed;

  Map<String, Object?> toJson() => _$PushStatusResponseToJson(this);
}
