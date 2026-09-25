// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_user.dart';

part 'login_verify_response.g.dart';

@JsonSerializable()
class LoginVerifyResponse {
  const LoginVerifyResponse({this.user});

  factory LoginVerifyResponse.fromJson(Map<String, Object?> json) =>
      _$LoginVerifyResponseFromJson(json);

  final SessionUser? user;

  Map<String, Object?> toJson() => _$LoginVerifyResponseToJson(this);
}
