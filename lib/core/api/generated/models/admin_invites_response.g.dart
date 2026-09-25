// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_invites_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminInvitesResponse _$AdminInvitesResponseFromJson(
  Map<String, dynamic> json,
) => AdminInvitesResponse(
  invites: (json['invites'] as List<dynamic>?)
      ?.map((e) => Invite.fromJson(e as Map<String, dynamic>))
      .toList(),
  inviteOnly: json['invite_only'] as bool?,
);

Map<String, dynamic> _$AdminInvitesResponseToJson(
  AdminInvitesResponse instance,
) => <String, dynamic>{
  'invites': instance.invites,
  'invite_only': instance.inviteOnly,
};
