// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_user.dart';

part 'pair_redeem_response.g.dart';

@JsonSerializable()
class PairRedeemResponse {
  const PairRedeemResponse({this.token, this.user});

  factory PairRedeemResponse.fromJson(Map<String, Object?> json) =>
      _$PairRedeemResponseFromJson(json);

  /// Signed session token, valid for SESSION_DAYS.
  final String? token;
  final SessionUser? user;

  Map<String, Object?> toJson() => _$PairRedeemResponseToJson(this);
}
