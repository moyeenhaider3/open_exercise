// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_user_detail_user.g.dart';

@JsonSerializable()
class AdminUserDetailUser {
  const AdminUserDetailUser({
    this.id,
    this.name,
    this.created,
    this.disabled,
    this.admin,
    this.invitedBy,
  });

  factory AdminUserDetailUser.fromJson(Map<String, Object?> json) =>
      _$AdminUserDetailUserFromJson(json);

  final String? id;
  final String? name;
  final String? created;
  final bool? disabled;
  final bool? admin;
  final String? invitedBy;

  Map<String, Object?> toJson() => _$AdminUserDetailUserToJson(this);
}
