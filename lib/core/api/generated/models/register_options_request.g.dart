// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_options_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterOptionsRequest _$RegisterOptionsRequestFromJson(
  Map<String, dynamic> json,
) => RegisterOptionsRequest(
  name: json['name'] as String,
  code: json['code'] as String?,
);

Map<String, dynamic> _$RegisterOptionsRequestToJson(
  RegisterOptionsRequest instance,
) => <String, dynamic>{'name': instance.name, 'code': instance.code};
