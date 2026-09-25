// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEvent _$AuditEventFromJson(Map<String, dynamic> json) => AuditEvent(
  id: (json['id'] as num).toInt(),
  ts: json['ts'] as num,
  ev: json['ev'] as String,
  ok: json['ok'] as bool,
  uid: json['uid'] as String?,
  name: json['name'] as String?,
  tgt: json['tgt'] as String?,
  tname: json['tname'] as String?,
  msg: json['msg'] as String?,
  ip: json['ip'] as String?,
);

Map<String, dynamic> _$AuditEventToJson(AuditEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ts': instance.ts,
      'ev': instance.ev,
      'ok': instance.ok,
      'uid': instance.uid,
      'name': instance.name,
      'tgt': instance.tgt,
      'tname': instance.tname,
      'msg': instance.msg,
      'ip': instance.ip,
    };
