// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_disable_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserDisableResponse _$AdminUserDisableResponseFromJson(
  Map<String, dynamic> json,
) => AdminUserDisableResponse(
  ok: json['ok'] as bool?,
  id: json['id'] as String?,
  disabled: json['disabled'] as bool?,
);

Map<String, dynamic> _$AdminUserDisableResponseToJson(
  AdminUserDisableResponse instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'id': instance.id,
  'disabled': instance.disabled,
};
