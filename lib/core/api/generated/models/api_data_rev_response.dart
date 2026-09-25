// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'api_data_rev_response.g.dart';

@JsonSerializable()
class ApiDataRevResponse {
  const ApiDataRevResponse({this.rev});

  factory ApiDataRevResponse.fromJson(Map<String, Object?> json) =>
      _$ApiDataRevResponseFromJson(json);

  final int? rev;

  Map<String, Object?> toJson() => _$ApiDataRevResponseToJson(this);
}
