// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_detail_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserDetailUser _$AdminUserDetailUserFromJson(Map<String, dynamic> json) =>
    AdminUserDetailUser(
      id: json['id'] as String?,
      name: json['name'] as String?,
      created: json['created'] as String?,
      disabled: json['disabled'] as bool?,
      admin: json['admin'] as bool?,
      invitedBy: json['invitedBy'] as String?,
    );

Map<String, dynamic> _$AdminUserDetailUserToJson(
  AdminUserDetailUser instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'created': instance.created,
  'disabled': instance.disabled,
  'admin': instance.admin,
  'invitedBy': instance.invitedBy,
};
