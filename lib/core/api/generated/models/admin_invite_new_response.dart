// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invite.dart';

part 'admin_invite_new_response.g.dart';

@JsonSerializable()
class AdminInviteNewResponse {
  const AdminInviteNewResponse({this.invite});

  factory AdminInviteNewResponse.fromJson(Map<String, Object?> json) =>
      _$AdminInviteNewResponseFromJson(json);

  final Invite? invite;

  Map<String, Object?> toJson() => _$AdminInviteNewResponseToJson(this);
}
