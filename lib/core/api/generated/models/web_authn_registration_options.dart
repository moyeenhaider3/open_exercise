// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_registration_options_authenticator_selection.dart';
import 'web_authn_registration_options_rp.dart';
import 'web_authn_registration_options_user.dart';

part 'web_authn_registration_options.g.dart';

/// PublicKeyCredentialCreationOptionsJSON — pass to `startRegistration()` (@simplewebauthn/browser) or decode for `navigator.credentials.create()`. Resident keys are required; attestation is `none`.
@JsonSerializable()
class WebAuthnRegistrationOptions {
  const WebAuthnRegistrationOptions({
    this.challenge,
    this.rp,
    this.user,
    this.pubKeyCredParams,
    this.authenticatorSelection,
    this.attestation,
  });

  factory WebAuthnRegistrationOptions.fromJson(Map<String, Object?> json) =>
      _$WebAuthnRegistrationOptionsFromJson(json);

  /// base64url
  final String? challenge;
  final WebAuthnRegistrationOptionsRp? rp;
  final WebAuthnRegistrationOptionsUser? user;
  final List<dynamic>? pubKeyCredParams;
  final WebAuthnRegistrationOptionsAuthenticatorSelection?
  authenticatorSelection;
  final String? attestation;

  Map<String, Object?> toJson() => _$WebAuthnRegistrationOptionsToJson(this);
}
