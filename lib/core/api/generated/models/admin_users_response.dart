// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_user_row.dart';

part 'admin_users_response.g.dart';

@JsonSerializable()
class AdminUsersResponse {
  const AdminUsersResponse({this.users, this.inviteOnly, this.now});

  factory AdminUsersResponse.fromJson(Map<String, Object?> json) =>
      _$AdminUsersResponseFromJson(json);

  final List<AdminUserRow>? users;
  @JsonKey(name: 'invite_only')
  final bool? inviteOnly;

  /// Server time (ms) — for rendering relative times.
  final num? now;

  Map<String, Object?> toJson() => _$AdminUsersResponseToJson(this);
}
