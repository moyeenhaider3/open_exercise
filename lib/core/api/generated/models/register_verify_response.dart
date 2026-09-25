// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_user.dart';

part 'register_verify_response.g.dart';

@JsonSerializable()
class RegisterVerifyResponse {
  const RegisterVerifyResponse({this.user});

  factory RegisterVerifyResponse.fromJson(Map<String, Object?> json) =>
      _$RegisterVerifyResponseFromJson(json);

  final SessionUser? user;

  Map<String, Object?> toJson() => _$RegisterVerifyResponseToJson(this);
}
