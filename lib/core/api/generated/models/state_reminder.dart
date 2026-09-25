// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'state_reminder.g.dart';

@JsonSerializable()
class StateReminder {
  const StateReminder({this.onField, this.time, this.tz});

  factory StateReminder.fromJson(Map<String, Object?> json) =>
      _$StateReminderFromJson(json);

  @JsonKey(name: 'on')
  final bool? onField;
  final String? time;

  /// IANA zone ("Europe/Zurich"); the user's own clock.
  final String? tz;

  Map<String, Object?> toJson() => _$StateReminderToJson(this);
}
