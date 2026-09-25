// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pair_redeem_request.g.dart';

@JsonSerializable()
class PairRedeemRequest {
  const PairRedeemRequest({required this.code});

  factory PairRedeemRequest.fromJson(Map<String, Object?> json) =>
      _$PairRedeemRequestFromJson(json);

  /// The pairing code (case-insensitive).
  final String code;

  Map<String, Object?> toJson() => _$PairRedeemRequestToJson(this);
}
