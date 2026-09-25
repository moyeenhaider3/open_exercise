// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_authentication_options.dart';

part 'login_options_response.g.dart';

@JsonSerializable()
class LoginOptionsResponse {
  const LoginOptionsResponse({this.cid, this.options});

  factory LoginOptionsResponse.fromJson(Map<String, Object?> json) =>
      _$LoginOptionsResponseFromJson(json);

  final String? cid;
  final WebAuthnAuthenticationOptions? options;

  Map<String, Object?> toJson() => _$LoginOptionsResponseToJson(this);
}
