// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_authentication_credential_response.dart';

part 'web_authn_authentication_credential.g.dart';

/// AuthenticationResponseJSON — the value `startAuthentication()` resolves with, sent back verbatim.
@JsonSerializable()
class WebAuthnAuthenticationCredential {
  const WebAuthnAuthenticationCredential({
    this.id,
    this.rawId,
    this.type,
    this.response,
  });

  factory WebAuthnAuthenticationCredential.fromJson(
    Map<String, Object?> json,
  ) => _$WebAuthnAuthenticationCredentialFromJson(json);

  /// base64url credential id
  final String? id;
  final String? rawId;
  final String? type;
  final WebAuthnAuthenticationCredentialResponse? response;

  Map<String, Object?> toJson() =>
      _$WebAuthnAuthenticationCredentialToJson(this);
}
