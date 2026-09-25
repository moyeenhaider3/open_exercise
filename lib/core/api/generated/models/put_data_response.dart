// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'put_data_response.g.dart';

@JsonSerializable()
class PutDataResponse {
  const PutDataResponse({this.ok, this.ts, this.rev});

  factory PutDataResponse.fromJson(Map<String, Object?> json) =>
      _$PutDataResponseFromJson(json);

  final bool? ok;

  /// Echo of the pushed state's `_ts`, if present.
  final num? ts;

  /// The revision the write produced.
  final int? rev;

  Map<String, Object?> toJson() => _$PutDataResponseToJson(this);
}
