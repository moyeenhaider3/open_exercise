// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bodyweight_entry.g.dart';

@JsonSerializable()
class BodyweightEntry {
  const BodyweightEntry({this.d, this.w, this.t});

  factory BodyweightEntry.fromJson(Map<String, Object?> json) =>
      _$BodyweightEntryFromJson(json);

  final DateTime? d;

  /// Weight in `unit`.
  final num? w;

  /// Timestamp (ms).
  final num? t;

  Map<String, Object?> toJson() => _$BodyweightEntryToJson(this);
}
