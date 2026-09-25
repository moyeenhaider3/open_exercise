// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginVerifyRequest _$LoginVerifyRequestFromJson(Map<String, dynamic> json) =>
    LoginVerifyRequest(
      cid: json['cid'] as String,
      credential: WebAuthnAuthenticationCredential.fromJson(
        json['credential'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LoginVerifyRequestToJson(LoginVerifyRequest instance) =>
    <String, dynamic>{'cid': instance.cid, 'credential': instance.credential};
