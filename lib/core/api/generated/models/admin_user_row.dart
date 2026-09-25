// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'presence.dart';

part 'admin_user_row.g.dart';

@JsonSerializable()
class AdminUserRow {
  const AdminUserRow({
    this.id,
    this.name,
    this.created,
    this.disabled,
    this.admin,
    this.invitedBy,
    this.workouts,
    this.lastWorkout,
    this.lastSync,
    this.hasPush,
    this.live,
  });

  factory AdminUserRow.fromJson(Map<String, Object?> json) =>
      _$AdminUserRowFromJson(json);

  final String? id;
  final String? name;

  /// ISO timestamp.
  final String? created;
  final bool? disabled;
  final bool? admin;

  /// The invite code this account was created with.
  final String? invitedBy;

  /// Total logged workouts.
  final int? workouts;

  /// ISO day of the newest workout.
  final String? lastWorkout;

  /// The state's `_ts` (ms).
  final num? lastSync;

  /// Has at least one push subscription.
  final bool? hasPush;

  /// Currently training, or null.
  final Presence? live;

  Map<String, Object?> toJson() => _$AdminUserRowToJson(this);
}
