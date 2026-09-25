// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_invite_new_request.g.dart';

@JsonSerializable()
class AdminInviteNewRequest {
  const AdminInviteNewRequest({this.note});

  factory AdminInviteNewRequest.fromJson(Map<String, Object?> json) =>
      _$AdminInviteNewRequestFromJson(json);

  /// Free-form label ("for Alex").
  final String? note;

  Map<String, Object?> toJson() => _$AdminInviteNewRequestToJson(this);
}
