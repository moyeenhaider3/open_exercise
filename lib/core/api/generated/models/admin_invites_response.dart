// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invite.dart';

part 'admin_invites_response.g.dart';

@JsonSerializable()
class AdminInvitesResponse {
  const AdminInvitesResponse({this.invites, this.inviteOnly});

  factory AdminInvitesResponse.fromJson(Map<String, Object?> json) =>
      _$AdminInvitesResponseFromJson(json);

  final List<Invite>? invites;
  @JsonKey(name: 'invite_only')
  final bool? inviteOnly;

  Map<String, Object?> toJson() => _$AdminInvitesResponseToJson(this);
}
