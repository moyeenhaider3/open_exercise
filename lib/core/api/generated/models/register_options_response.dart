// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'web_authn_registration_options.dart';

part 'register_options_response.g.dart';

@JsonSerializable()
class RegisterOptionsResponse {
  const RegisterOptionsResponse({this.cid, this.options});

  factory RegisterOptionsResponse.fromJson(Map<String, Object?> json) =>
      _$RegisterOptionsResponseFromJson(json);

  /// One-shot challenge id, echo it back to /api/register/verify.
  final String? cid;
  final WebAuthnRegistrationOptions? options;

  Map<String, Object?> toJson() => _$RegisterOptionsResponseToJson(this);
}
