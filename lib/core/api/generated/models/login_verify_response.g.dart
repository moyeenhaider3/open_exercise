// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_verify_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginVerifyResponse _$LoginVerifyResponseFromJson(Map<String, dynamic> json) =>
    LoginVerifyResponse(
      user: json['user'] == null
          ? null
          : SessionUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginVerifyResponseToJson(
  LoginVerifyResponse instance,
) => <String, dynamic>{'user': instance.user};
