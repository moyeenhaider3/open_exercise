// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

/// A workout template (representative shape).
@JsonSerializable()
class Routine {
  const Routine({this.id, this.name, this.emoji, this.ex});

  factory Routine.fromJson(Map<String, Object?> json) =>
      _$RoutineFromJson(json);

  final String? id;
  final String? name;
  final String? emoji;

  /// Exercises with set/rep targets.
  final List<dynamic>? ex;

  Map<String, Object?> toJson() => _$RoutineToJson(this);
}
