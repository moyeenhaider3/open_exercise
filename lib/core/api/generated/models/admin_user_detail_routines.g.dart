// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_detail_routines.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserDetailRoutines _$AdminUserDetailRoutinesFromJson(
  Map<String, dynamic> json,
) => AdminUserDetailRoutines(
  id: json['id'] as String?,
  name: json['name'] as String?,
  emoji: json['emoji'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$AdminUserDetailRoutinesToJson(
  AdminUserDetailRoutines instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'count': instance.count,
};
