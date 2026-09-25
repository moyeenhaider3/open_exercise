// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_authentication_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnAuthenticationOptions _$WebAuthnAuthenticationOptionsFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthenticationOptions(
  challenge: json['challenge'] as String?,
  rpId: json['rpId'] as String?,
  userVerification: json['userVerification'] as String?,
  allowCredentials: json['allowCredentials'] as List<dynamic>?,
);

Map<String, dynamic> _$WebAuthnAuthenticationOptionsToJson(
  WebAuthnAuthenticationOptions instance,
) => <String, dynamic>{
  'challenge': instance.challenge,
  'rpId': instance.rpId,
  'userVerification': instance.userVerification,
  'allowCredentials': instance.allowCredentials,
};
