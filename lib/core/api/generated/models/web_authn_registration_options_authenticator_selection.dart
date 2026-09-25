// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_registration_options_authenticator_selection.g.dart';

@JsonSerializable()
class WebAuthnRegistrationOptionsAuthenticatorSelection {
  const WebAuthnRegistrationOptionsAuthenticatorSelection({
    this.residentKey,
    this.userVerification,
  });

  factory WebAuthnRegistrationOptionsAuthenticatorSelection.fromJson(
    Map<String, Object?> json,
  ) => _$WebAuthnRegistrationOptionsAuthenticatorSelectionFromJson(json);

  final String? residentKey;
  final String? userVerification;

  Map<String, Object?> toJson() =>
      _$WebAuthnRegistrationOptionsAuthenticatorSelectionToJson(this);
}
