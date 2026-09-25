// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_authentication_options.g.dart';

/// PublicKeyCredentialRequestOptionsJSON — pass to `startAuthentication()`. `allowCredentials` is empty: the browser offers the user's discoverable passkeys itself.
@JsonSerializable()
class WebAuthnAuthenticationOptions {
  const WebAuthnAuthenticationOptions({
    this.challenge,
    this.rpId,
    this.userVerification,
    this.allowCredentials,
  });

  factory WebAuthnAuthenticationOptions.fromJson(Map<String, Object?> json) =>
      _$WebAuthnAuthenticationOptionsFromJson(json);

  /// base64url
  final String? challenge;
  final String? rpId;
  final String? userVerification;

  /// Always empty.
  final List<dynamic>? allowCredentials;

  Map<String, Object?> toJson() => _$WebAuthnAuthenticationOptionsToJson(this);
}
