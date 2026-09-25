// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'workout_entries_sets.g.dart';

@JsonSerializable()
class WorkoutEntriesSets {
  const WorkoutEntriesSets({this.w, this.r, this.done, this.rir, this.rpe});

  factory WorkoutEntriesSets.fromJson(Map<String, Object?> json) =>
      _$WorkoutEntriesSetsFromJson(json);

  /// Weight.
  final num? w;

  /// Reps.
  final num? r;
  final bool? done;
  final num? rir;
  final num? rpe;

  Map<String, Object?> toJson() => _$WorkoutEntriesSetsToJson(this);
}
