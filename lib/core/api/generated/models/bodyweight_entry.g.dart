// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bodyweight_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyweightEntry _$BodyweightEntryFromJson(Map<String, dynamic> json) =>
    BodyweightEntry(
      d: json['d'] == null ? null : DateTime.parse(json['d'] as String),
      w: json['w'] as num?,
      t: json['t'] as num?,
    );

Map<String, dynamic> _$BodyweightEntryToJson(BodyweightEntry instance) =>
    <String, dynamic>{
      'd': instance.d?.toIso8601String(),
      'w': instance.w,
      't': instance.t,
    };
