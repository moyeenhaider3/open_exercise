// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'workout_entries_sets.dart';

part 'workout_entries.g.dart';

@JsonSerializable()
class WorkoutEntries {
  const WorkoutEntries({this.id, this.topW, this.sets});

  factory WorkoutEntries.fromJson(Map<String, Object?> json) =>
      _$WorkoutEntriesFromJson(json);

  /// Exercise id.
  final String? id;
  final num? topW;
  final List<WorkoutEntriesSets>? sets;

  Map<String, Object?> toJson() => _$WorkoutEntriesToJson(this);
}
