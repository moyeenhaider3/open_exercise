// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_health_response.g.dart';

@JsonSerializable()
class GetHealthResponse {
  const GetHealthResponse({this.ok, this.users});

  factory GetHealthResponse.fromJson(Map<String, Object?> json) =>
      _$GetHealthResponseFromJson(json);

  final bool? ok;

  /// Number of registered user accounts.
  final int? users;

  Map<String, Object?> toJson() => _$GetHealthResponseToJson(this);
}
