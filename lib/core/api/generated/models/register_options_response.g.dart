// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_options_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOptionsResponse _$RegisterOptionsResponseFromJson(
  Map<String, dynamic> json,
) => RegisterOptionsResponse(
  cid: json['cid'] as String?,
  options: json['options'] == null
      ? null
      : WebAuthnRegistrationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$RegisterOptionsResponseToJson(
  RegisterOptionsResponse instance,
) => <String, dynamic>{'cid': instance.cid, 'options': instance.options};
