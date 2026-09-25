// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_registration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnRegistrationOptions _$WebAuthnRegistrationOptionsFromJson(
  Map<String, dynamic> json,
) => WebAuthnRegistrationOptions(
  challenge: json['challenge'] as String?,
  rp: json['rp'] == null
      ? null
      : WebAuthnRegistrationOptionsRp.fromJson(
          json['rp'] as Map<String, dynamic>,
        ),
  user: json['user'] == null
      ? null
      : WebAuthnRegistrationOptionsUser.fromJson(
          json['user'] as Map<String, dynamic>,
        ),
  pubKeyCredParams: json['pubKeyCredParams'] as List<dynamic>?,
  authenticatorSelection: json['authenticatorSelection'] == null
      ? null
      : WebAuthnRegistrationOptionsAuthenticatorSelection.fromJson(
          json['authenticatorSelection'] as Map<String, dynamic>,
        ),
  attestation: json['attestation'] as String?,
);

Map<String, dynamic> _$WebAuthnRegistrationOptionsToJson(
  WebAuthnRegistrationOptions instance,
) => <String, dynamic>{
  'challenge': instance.challenge,
  'rp': instance.rp,
  'user': instance.user,
  'pubKeyCredParams': instance.pubKeyCredParams,
  'authenticatorSelection': instance.authenticatorSelection,
  'attestation': instance.attestation,
};
