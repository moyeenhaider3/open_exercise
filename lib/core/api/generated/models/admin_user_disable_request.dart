// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_user_disable_request.g.dart';

@JsonSerializable()
class AdminUserDisableRequest {
  const AdminUserDisableRequest({required this.id, required this.disabled});

  factory AdminUserDisableRequest.fromJson(Map<String, Object?> json) =>
      _$AdminUserDisableRequestFromJson(json);

  /// The user id.
  final String id;
  final bool disabled;

  Map<String, Object?> toJson() => _$AdminUserDisableRequestToJson(this);
}
