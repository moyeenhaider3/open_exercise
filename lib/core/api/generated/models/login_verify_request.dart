// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_authentication_credential.dart';

part 'login_verify_request.g.dart';

@JsonSerializable()
class LoginVerifyRequest {
  const LoginVerifyRequest({required this.cid, required this.credential});

  factory LoginVerifyRequest.fromJson(Map<String, Object?> json) =>
      _$LoginVerifyRequestFromJson(json);

  /// The challenge id from /api/login/options.
  final String cid;
  final WebAuthnAuthenticationCredential credential;

  Map<String, Object?> toJson() => _$LoginVerifyRequestToJson(this);
}
