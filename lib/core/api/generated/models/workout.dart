// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'workout_entries.dart';

part 'workout.g.dart';

/// One completed workout (representative shape).
@JsonSerializable()
class Workout {
  const Workout({
    this.id,
    this.d,
    this.start,
    this.end,
    this.routineId,
    this.name,
    this.bw,
    this.vol,
    this.prs,
    this.entries,
  });

  factory Workout.fromJson(Map<String, Object?> json) =>
      _$WorkoutFromJson(json);

  final String? id;

  /// ISO day, e.g. "2026-08-30".
  final DateTime? d;

  /// ms since epoch
  final num? start;
  final num? end;
  final String? routineId;
  final String? name;

  /// Body weight that day, in `unit`.
  final num? bw;

  /// Total volume (Σ weight × reps).
  final num? vol;

  /// Exercise ids that hit a personal record.
  final List<String>? prs;
  final List<WorkoutEntries>? entries;

  Map<String, Object?> toJson() => _$WorkoutToJson(this);
}
