// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserRow _$AdminUserRowFromJson(Map<String, dynamic> json) => AdminUserRow(
  id: json['id'] as String?,
  name: json['name'] as String?,
  created: json['created'] as String?,
  disabled: json['disabled'] as bool?,
  admin: json['admin'] as bool?,
  invitedBy: json['invitedBy'] as String?,
  workouts: (json['workouts'] as num?)?.toInt(),
  lastWorkout: json['lastWorkout'] as String?,
  lastSync: json['lastSync'] as num?,
  hasPush: json['hasPush'] as bool?,
  live: json['live'] == null
      ? null
      : Presence.fromJson(json['live'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminUserRowToJson(AdminUserRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created': instance.created,
      'disabled': instance.disabled,
      'admin': instance.admin,
      'invitedBy': instance.invitedBy,
      'workouts': instance.workouts,
      'lastWorkout': instance.lastWorkout,
      'lastSync': instance.lastSync,
      'hasPush': instance.hasPush,
      'live': instance.live,
    };
