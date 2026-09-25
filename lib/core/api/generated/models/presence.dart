// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'presence.g.dart';

/// Live-workout snapshot (from /api/activity heartbeats).
@JsonSerializable()
class Presence {
  const Presence({
    this.name,
    this.exIdx,
    this.exTotal,
    this.setsDone,
    this.setsTotal,
    this.startedAt,
    this.updatedAt,
  });

  factory Presence.fromJson(Map<String, Object?> json) =>
      _$PresenceFromJson(json);

  final String? name;
  final int? exIdx;
  final int? exTotal;
  final int? setsDone;
  final int? setsTotal;
  final num? startedAt;
  final num? updatedAt;

  Map<String, Object?> toJson() => _$PresenceToJson(this);
}
