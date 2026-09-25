// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'state.dart';

part 'put_data_request.g.dart';

@JsonSerializable()
class PutDataRequest {
  const PutDataRequest({required this.state, this.baseRev});

  factory PutDataRequest.fromJson(Map<String, Object?> json) =>
      _$PutDataRequestFromJson(json);

  final State state;

  /// The revision this client last read or wrote. Omit or null for an unconditional overwrite.
  final int? baseRev;

  Map<String, Object?> toJson() => _$PutDataRequestToJson(this);
}
