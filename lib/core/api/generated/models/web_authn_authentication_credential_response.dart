// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_authentication_credential_response.g.dart';

@JsonSerializable()
class WebAuthnAuthenticationCredentialResponse {
  const WebAuthnAuthenticationCredentialResponse({
    this.clientDataJson,
    this.authenticatorData,
    this.signature,
    this.userHandle,
  });

  factory WebAuthnAuthenticationCredentialResponse.fromJson(
    Map<String, Object?> json,
  ) => _$WebAuthnAuthenticationCredentialResponseFromJson(json);

  @JsonKey(name: 'clientDataJSON')
  final String? clientDataJson;
  final String? authenticatorData;
  final String? signature;
  final String? userHandle;

  Map<String, Object?> toJson() =>
      _$WebAuthnAuthenticationCredentialResponseToJson(this);
}
