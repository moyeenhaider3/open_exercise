// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_user_detail_routines.dart';
import 'admin_user_detail_unit_unit.dart';
import 'admin_user_detail_user.dart';
import 'bodyweight_entry.dart';
import 'workout.dart';

part 'admin_user_detail.g.dart';

@JsonSerializable()
class AdminUserDetail {
  const AdminUserDetail({
    this.user,
    this.unit,
    this.lastSync,
    this.routines,
    this.bodyweight,
    this.workouts,
  });

  factory AdminUserDetail.fromJson(Map<String, Object?> json) =>
      _$AdminUserDetailFromJson(json);

  final AdminUserDetailUser? user;
  final AdminUserDetailUnitUnit? unit;
  final num? lastSync;
  final List<AdminUserDetailRoutines>? routines;
  final List<BodyweightEntry>? bodyweight;

  /// Full history, newest first.
  final List<Workout>? workouts;

  Map<String, Object?> toJson() => _$AdminUserDetailToJson(this);
}
