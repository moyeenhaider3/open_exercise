// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_user_disable_response.g.dart';

@JsonSerializable()
class AdminUserDisableResponse {
  const AdminUserDisableResponse({this.ok, this.id, this.disabled});

  factory AdminUserDisableResponse.fromJson(Map<String, Object?> json) =>
      _$AdminUserDisableResponseFromJson(json);

  final bool? ok;
  final String? id;
  final bool? disabled;

  Map<String, Object?> toJson() => _$AdminUserDisableResponseToJson(this);
}
