// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_options_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginOptionsResponse _$LoginOptionsResponseFromJson(
  Map<String, dynamic> json,
) => LoginOptionsResponse(
  cid: json['cid'] as String?,
  options: json['options'] == null
      ? null
      : WebAuthnAuthenticationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$LoginOptionsResponseToJson(
  LoginOptionsResponse instance,
) => <String, dynamic>{'cid': instance.cid, 'options': instance.options};
