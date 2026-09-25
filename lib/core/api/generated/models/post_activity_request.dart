// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'post_activity_request.g.dart';

@JsonSerializable()
class PostActivityRequest {
  const PostActivityRequest({
    this.active,
    this.name,
    this.exIdx,
    this.exTotal,
    this.setsDone,
    this.setsTotal,
    this.startedAt,
  });

  factory PostActivityRequest.fromJson(Map<String, Object?> json) =>
      _$PostActivityRequestFromJson(json);

  /// false ends the presence; true (with the fields below) updates it.
  final bool? active;

  /// Routine/workout name being trained.
  final String? name;

  /// Current exercise index (0-based).
  final int? exIdx;

  /// Exercises in the workout.
  final int? exTotal;
  final int? setsDone;
  final int? setsTotal;

  /// Workout start, ms since epoch (defaults to now).
  final num? startedAt;

  Map<String, Object?> toJson() => _$PostActivityRequestToJson(this);
}
