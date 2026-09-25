// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'push_public_key_response.g.dart';

@JsonSerializable()
class PushPublicKeyResponse {
  const PushPublicKeyResponse({this.key});

  factory PushPublicKeyResponse.fromJson(Map<String, Object?> json) =>
      _$PushPublicKeyResponseFromJson(json);

  /// base64url-encoded P-256 public key.
  final String? key;

  Map<String, Object?> toJson() => _$PushPublicKeyResponseToJson(this);
}
