// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// How much of the caller IP is recorded (AUDIT_IP).
@JsonEnum()
enum AdminAuditResponseIpModeIpMode {
  @JsonValue('off')
  off('off'),
  @JsonValue('net')
  net('net'),
  @JsonValue('full')
  full('full'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AdminAuditResponseIpModeIpMode(this.json);

  factory AdminAuditResponseIpModeIpMode.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AdminAuditResponseIpModeIpMode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
