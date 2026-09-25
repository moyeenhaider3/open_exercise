// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_registration_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnRegistrationCredential _$WebAuthnRegistrationCredentialFromJson(
  Map<String, dynamic> json,
) => WebAuthnRegistrationCredential(
  id: json['id'] as String?,
  rawId: json['rawId'] as String?,
  type: json['type'] as String?,
  response: json['response'] == null
      ? null
      : WebAuthnRegistrationCredentialResponse.fromJson(
          json['response'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$WebAuthnRegistrationCredentialToJson(
  WebAuthnRegistrationCredential instance,
) => <String, dynamic>{
  'id': instance.id,
  'rawId': instance.rawId,
  'type': instance.type,
  'response': instance.response,
};
