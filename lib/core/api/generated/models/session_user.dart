// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'session_user.g.dart';

/// The caller's identity, as returned by /api/me and the sign-in routes.
@JsonSerializable()
class SessionUser {
  const SessionUser({this.id, this.name, this.admin});

  factory SessionUser.fromJson(Map<String, Object?> json) =>
      _$SessionUserFromJson(json);

  /// Stable user id (16 base64url chars).
  final String? id;
  final String? name;
  final bool? admin;

  Map<String, Object?> toJson() => _$SessionUserToJson(this);
}
