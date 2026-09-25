// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'invite.g.dart';

@JsonSerializable()
class Invite {
  const Invite({
    this.code,
    this.note,
    this.createdBy,
    this.created,
    this.usedBy,
    this.usedAt,
    this.usedByName,
  });

  factory Invite.fromJson(Map<String, Object?> json) => _$InviteFromJson(json);

  /// 16 hex chars.
  final String? code;
  final String? note;

  /// Admin user id.
  final String? createdBy;

  /// ISO timestamp.
  final String? created;

  /// User id that redeemed the code (absent/null while unused).
  final String? usedBy;
  final String? usedAt;

  /// Resolved display name (only in GET /api/admin/invites).
  final String? usedByName;

  Map<String, Object?> toJson() => _$InviteToJson(this);
}
