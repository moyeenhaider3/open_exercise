// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'audit_event.g.dart';

/// One line of the audit log.
@JsonSerializable()
class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.ts,
    required this.ev,
    required this.ok,
    this.uid,
    this.name,
    this.tgt,
    this.tname,
    this.msg,
    this.ip,
  });

  factory AuditEvent.fromJson(Map<String, Object?> json) =>
      _$AuditEventFromJson(json);

  /// Monotonic, never reset — a cleared log leaves a visible id gap.
  final int id;

  /// ms since epoch.
  final num ts;

  /// Event name. Currently one of:.
  /// `auth.register.ok|fail|denied`, `auth.login.ok|fail`, `auth.logout`,.
  /// `auth.logout.all`, `auth.pair.create|ok|fail`,.
  /// `admin.denied`, `admin.user.disable|enable`,.
  /// `admin.invite.create|revoke`, `admin.audit.clear`.
  ///
  final String ev;

  /// false for failed/denied attempts.
  final bool ok;

  /// Acting (or affected) user id.
  final String? uid;

  /// Acting user's name (max 40 chars).
  final String? name;

  /// Target user id (admin actions).
  final String? tgt;

  /// Target user's name.
  final String? tname;

  /// Short detail — a failure reason code, or the invite code involved. Rejected invite guesses and unknown credential ids are deliberately never recorded.
  final String? msg;

  /// Only when AUDIT_IP is on — the full address (`full`) or just the network, /24 or /48 (`net`).
  final String? ip;

  Map<String, Object?> toJson() => _$AuditEventToJson(this);
}
