// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_authentication_credential_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnAuthenticationCredentialResponse
_$WebAuthnAuthenticationCredentialResponseFromJson(Map<String, dynamic> json) =>
    WebAuthnAuthenticationCredentialResponse(
      clientDataJson: json['clientDataJSON'] as String?,
      authenticatorData: json['authenticatorData'] as String?,
      signature: json['signature'] as String?,
      userHandle: json['userHandle'] as String?,
    );

Map<String, dynamic> _$WebAuthnAuthenticationCredentialResponseToJson(
  WebAuthnAuthenticationCredentialResponse instance,
) => <String, dynamic>{
  'clientDataJSON': instance.clientDataJson,
  'authenticatorData': instance.authenticatorData,
  'signature': instance.signature,
  'userHandle': instance.userHandle,
};
