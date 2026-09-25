// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ok.g.dart';

@JsonSerializable()
class Ok {
  const Ok({this.ok});

  factory Ok.fromJson(Map<String, Object?> json) => _$OkFromJson(json);

  final bool? ok;

  Map<String, Object?> toJson() => _$OkToJson(this);
}
