// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pair_create_response.g.dart';

@JsonSerializable()
class PairCreateResponse {
  const PairCreateResponse({this.code});

  factory PairCreateResponse.fromJson(Map<String, Object?> json) =>
      _$PairCreateResponseFromJson(json);

  /// 8 chars from ABCDEFGHJKLMNPQRSTUVWXYZ23456789.
  final String? code;

  Map<String, Object?> toJson() => _$PairCreateResponseToJson(this);
}
