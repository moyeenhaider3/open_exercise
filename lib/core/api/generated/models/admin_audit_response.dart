// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'audit_event.dart';
import 'admin_audit_response_ip_mode_ip_mode.dart';
import 'admin_audit_response_retention.dart';

part 'admin_audit_response.g.dart';

@JsonSerializable()
class AdminAuditResponse {
  const AdminAuditResponse({
    this.events,
    this.total,
    this.nextBefore,
    this.enabled,
    this.ipMode,
    this.retention,
    this.now,
  });

  factory AdminAuditResponse.fromJson(Map<String, Object?> json) =>
      _$AdminAuditResponseFromJson(json);

  final List<AuditEvent>? events;

  /// Rows matching the filter (after retention).
  final int? total;

  /// Cursor for the next page; null on the last page.
  final int? nextBefore;

  /// Whether audit logging is currently on (AUDIT_LOG).
  final bool? enabled;

  /// How much of the caller IP is recorded (AUDIT_IP).
  @JsonKey(name: 'ip_mode')
  final AdminAuditResponseIpModeIpMode? ipMode;
  final AdminAuditResponseRetention? retention;

  /// Server time (ms).
  final num? now;

  Map<String, Object?> toJson() => _$AdminAuditResponseToJson(this);
}
