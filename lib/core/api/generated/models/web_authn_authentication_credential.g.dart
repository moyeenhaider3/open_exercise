// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_authentication_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnAuthenticationCredential _$WebAuthnAuthenticationCredentialFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthenticationCredential(
  id: json['id'] as String?,
  rawId: json['rawId'] as String?,
  type: json['type'] as String?,
  response: json['response'] == null
      ? null
      : WebAuthnAuthenticationCredentialResponse.fromJson(
          json['response'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$WebAuthnAuthenticationCredentialToJson(
  WebAuthnAuthenticationCredential instance,
) => <String, dynamic>{
  'id': instance.id,
  'rawId': instance.rawId,
  'type': instance.type,
  'response': instance.response,
};
