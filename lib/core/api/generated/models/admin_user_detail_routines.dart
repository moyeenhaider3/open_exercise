// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_user_detail_routines.g.dart';

@JsonSerializable()
class AdminUserDetailRoutines {
  const AdminUserDetailRoutines({this.id, this.name, this.emoji, this.count});

  factory AdminUserDetailRoutines.fromJson(Map<String, Object?> json) =>
      _$AdminUserDetailRoutinesFromJson(json);

  final String? id;
  final String? name;
  final String? emoji;

  /// Number of exercises.
  final int? count;

  Map<String, Object?> toJson() => _$AdminUserDetailRoutinesToJson(this);
}
