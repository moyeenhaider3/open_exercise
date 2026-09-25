// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_registration_credential.dart';

part 'register_verify_request.g.dart';

@JsonSerializable()
class RegisterVerifyRequest {
  const RegisterVerifyRequest({required this.cid, required this.credential});

  factory RegisterVerifyRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterVerifyRequestFromJson(json);

  /// The challenge id from /api/register/options.
  final String cid;
  final WebAuthnRegistrationCredential credential;

  Map<String, Object?> toJson() => _$RegisterVerifyRequestToJson(this);
}
