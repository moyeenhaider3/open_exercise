// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_invite_new_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminInviteNewResponse _$AdminInviteNewResponseFromJson(
  Map<String, dynamic> json,
) => AdminInviteNewResponse(
  invite: json['invite'] == null
      ? null
      : Invite.fromJson(json['invite'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminInviteNewResponseToJson(
  AdminInviteNewResponse instance,
) => <String, dynamic>{'invite': instance.invite};
