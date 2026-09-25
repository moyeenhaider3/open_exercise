// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StateReminder _$StateReminderFromJson(Map<String, dynamic> json) =>
    StateReminder(
      onField: json['on'] as bool?,
      time: json['time'] as String?,
      tz: json['tz'] as String?,
    );

Map<String, dynamic> _$StateReminderToJson(StateReminder instance) =>
    <String, dynamic>{
      'on': instance.onField,
      'time': instance.time,
      'tz': instance.tz,
    };
