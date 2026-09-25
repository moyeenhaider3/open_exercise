// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_registration_credential_response.dart';

part 'web_authn_registration_credential.g.dart';

/// RegistrationResponseJSON — the value `startRegistration()` resolves with (the created credential plus the authenticator's attestation response), sent back verbatim.
@JsonSerializable()
class WebAuthnRegistrationCredential {
  const WebAuthnRegistrationCredential({
    this.id,
    this.rawId,
    this.type,
    this.response,
  });

  factory WebAuthnRegistrationCredential.fromJson(Map<String, Object?> json) =>
      _$WebAuthnRegistrationCredentialFromJson(json);

  /// base64url credential id
  final String? id;
  final String? rawId;
  final String? type;
  final WebAuthnRegistrationCredentialResponse? response;

  Map<String, Object?> toJson() => _$WebAuthnRegistrationCredentialToJson(this);
}
