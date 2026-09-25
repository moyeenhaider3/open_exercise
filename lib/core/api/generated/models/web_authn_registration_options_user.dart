// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_registration_options_user.g.dart';

@JsonSerializable()
class WebAuthnRegistrationOptionsUser {
  const WebAuthnRegistrationOptionsUser({this.id, this.name, this.displayName});

  factory WebAuthnRegistrationOptionsUser.fromJson(Map<String, Object?> json) =>
      _$WebAuthnRegistrationOptionsUserFromJson(json);

  /// base64url user handle
  final String? id;
  final String? name;
  final String? displayName;

  Map<String, Object?> toJson() =>
      _$WebAuthnRegistrationOptionsUserToJson(this);
}
