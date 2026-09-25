// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_options_request.g.dart';

@JsonSerializable()
class RegisterOptionsRequest {
  const RegisterOptionsRequest({required this.name, this.code});

  factory RegisterOptionsRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterOptionsRequestFromJson(json);

  /// Display name for the new profile (trimmed, max 40 chars).
  final String name;

  /// Invite code — required (and validated) only when the instance runs with INVITE_ONLY. Compared case-insensitively.
  final String? code;

  Map<String, Object?> toJson() => _$RegisterOptionsRequestToJson(this);
}
