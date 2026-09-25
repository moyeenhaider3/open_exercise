// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_authn_registration_credential_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnRegistrationCredentialResponse
_$WebAuthnRegistrationCredentialResponseFromJson(Map<String, dynamic> json) =>
    WebAuthnRegistrationCredentialResponse(
      clientDataJson: json['clientDataJSON'] as String?,
      attestationObject: json['attestationObject'] as String?,
      transports: (json['transports'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WebAuthnRegistrationCredentialResponseToJson(
  WebAuthnRegistrationCredentialResponse instance,
) => <String, dynamic>{
  'clientDataJSON': instance.clientDataJson,
  'attestationObject': instance.attestationObject,
  'transports': instance.transports,
};
