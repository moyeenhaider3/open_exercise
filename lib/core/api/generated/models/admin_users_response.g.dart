// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_users_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUsersResponse _$AdminUsersResponseFromJson(Map<String, dynamic> json) =>
    AdminUsersResponse(
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => AdminUserRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      inviteOnly: json['invite_only'] as bool?,
      now: json['now'] as num?,
    );

Map<String, dynamic> _$AdminUsersResponseToJson(AdminUsersResponse instance) =>
    <String, dynamic>{
      'users': instance.users,
      'invite_only': instance.inviteOnly,
      'now': instance.now,
    };
