// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserDetail _$AdminUserDetailFromJson(Map<String, dynamic> json) =>
    AdminUserDetail(
      user: json['user'] == null
          ? null
          : AdminUserDetailUser.fromJson(json['user'] as Map<String, dynamic>),
      unit: json['unit'] == null
          ? null
          : AdminUserDetailUnitUnit.fromJson(json['unit'] as String),
      lastSync: json['lastSync'] as num?,
      routines: (json['routines'] as List<dynamic>?)
          ?.map(
            (e) => AdminUserDetailRoutines.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      bodyweight: (json['bodyweight'] as List<dynamic>?)
          ?.map((e) => BodyweightEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      workouts: (json['workouts'] as List<dynamic>?)
          ?.map((e) => Workout.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AdminUserDetailToJson(AdminUserDetail instance) =>
    <String, dynamic>{
      'user': instance.user,
      'unit': instance.unit,
      'lastSync': instance.lastSync,
      'routines': instance.routines,
      'bodyweight': instance.bodyweight,
      'workouts': instance.workouts,
    };
