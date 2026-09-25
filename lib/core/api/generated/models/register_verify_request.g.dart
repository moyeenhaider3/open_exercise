// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterVerifyRequest _$RegisterVerifyRequestFromJson(
  Map<String, dynamic> json,
) => RegisterVerifyRequest(
  cid: json['cid'] as String,
  credential: WebAuthnRegistrationCredential.fromJson(
    json['credential'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$RegisterVerifyRequestToJson(
  RegisterVerifyRequest instance,
) => <String, dynamic>{'cid': instance.cid, 'credential': instance.credential};
