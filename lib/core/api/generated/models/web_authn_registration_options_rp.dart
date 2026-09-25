// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_authn_registration_options_rp.g.dart';

@JsonSerializable()
class WebAuthnRegistrationOptionsRp {
  const WebAuthnRegistrationOptionsRp({this.name, this.id});

  factory WebAuthnRegistrationOptionsRp.fromJson(Map<String, Object?> json) =>
      _$WebAuthnRegistrationOptionsRpFromJson(json);

  final String? name;

  /// The RP_ID the instance is configured with.
  final String? id;

  Map<String, Object?> toJson() => _$WebAuthnRegistrationOptionsRpToJson(this);
}
