// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'state.dart';

part 'get_data_response.g.dart';

@JsonSerializable()
class GetDataResponse {
  const GetDataResponse({this.state, this.rev});

  factory GetDataResponse.fromJson(Map<String, Object?> json) =>
      _$GetDataResponseFromJson(json);

  final State? state;

  /// Server revision of the stored document; 0 when there is none.
  final int? rev;

  Map<String, Object?> toJson() => _$GetDataResponseToJson(this);
}
