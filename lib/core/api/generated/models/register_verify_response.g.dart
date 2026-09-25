// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_verify_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterVerifyResponse _$RegisterVerifyResponseFromJson(
  Map<String, dynamic> json,
) => RegisterVerifyResponse(
  user: json['user'] == null
      ? null
      : SessionUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RegisterVerifyResponseToJson(
  RegisterVerifyResponse instance,
) => <String, dynamic>{'user': instance.user};
