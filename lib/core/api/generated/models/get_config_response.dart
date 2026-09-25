// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_config_response.g.dart';

@JsonSerializable()
class GetConfigResponse {
  const GetConfigResponse({this.inviteOnly, this.allowGuest});

  factory GetConfigResponse.fromJson(Map<String, Object?> json) =>
      _$GetConfigResponseFromJson(json);

  /// When true, registration requires a valid invite code.
  @JsonKey(name: 'invite_only')
  final bool? inviteOnly;

  /// When false, the client hides "continue without account". Guest mode is purely client-side and never calls this API.
  @JsonKey(name: 'allow_guest')
  final bool? allowGuest;

  Map<String, Object?> toJson() => _$GetConfigResponseToJson(this);
}
