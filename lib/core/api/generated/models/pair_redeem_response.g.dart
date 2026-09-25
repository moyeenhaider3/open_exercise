// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_redeem_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PairRedeemResponse _$PairRedeemResponseFromJson(Map<String, dynamic> json) =>
    PairRedeemResponse(
      token: json['token'] as String?,
      user: json['user'] == null
          ? null
          : SessionUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PairRedeemResponseToJson(PairRedeemResponse instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};
