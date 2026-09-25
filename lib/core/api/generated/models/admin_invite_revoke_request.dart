// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_invite_revoke_request.g.dart';

@JsonSerializable()
class AdminInviteRevokeRequest {
  const AdminInviteRevokeRequest({required this.code});

  factory AdminInviteRevokeRequest.fromJson(Map<String, Object?> json) =>
      _$AdminInviteRevokeRequestFromJson(json);

  final String code;

  Map<String, Object?> toJson() => _$AdminInviteRevokeRequestToJson(this);
}
