// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_audit_response_retention.g.dart';

@JsonSerializable()
class AdminAuditResponseRetention {
  const AdminAuditResponseRetention({this.max, this.days});

  factory AdminAuditResponseRetention.fromJson(Map<String, Object?> json) =>
      _$AdminAuditResponseRetentionFromJson(json);

  /// Event cap (0 = none).
  final int? max;

  /// Age cap in days (0 = none).
  final int? days;

  Map<String, Object?> toJson() => _$AdminAuditResponseRetentionToJson(this);
}
