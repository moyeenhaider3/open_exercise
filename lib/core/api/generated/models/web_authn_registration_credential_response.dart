// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_registration_credential_response.g.dart';

@JsonSerializable()
class WebAuthnRegistrationCredentialResponse {
  const WebAuthnRegistrationCredentialResponse({
    this.clientDataJson,
    this.attestationObject,
    this.transports,
  });

  factory WebAuthnRegistrationCredentialResponse.fromJson(
    Map<String, Object?> json,
  ) => _$WebAuthnRegistrationCredentialResponseFromJson(json);

  /// base64url
  @JsonKey(name: 'clientDataJSON')
  final String? clientDataJson;

  /// base64url
  final String? attestationObject;

  /// e.g. ["internal", "hybrid"] — stored for later logins.
  final List<String>? transports;

  Map<String, Object?> toJson() =>
      _$WebAuthnRegistrationCredentialResponseToJson(this);
}
