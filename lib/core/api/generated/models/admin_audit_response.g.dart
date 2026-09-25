// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAuditResponse _$AdminAuditResponseFromJson(Map<String, dynamic> json) =>
    AdminAuditResponse(
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      nextBefore: (json['nextBefore'] as num?)?.toInt(),
      enabled: json['enabled'] as bool?,
      ipMode: json['ip_mode'] == null
          ? null
          : AdminAuditResponseIpModeIpMode.fromJson(json['ip_mode'] as String),
      retention: json['retention'] == null
          ? null
          : AdminAuditResponseRetention.fromJson(
              json['retention'] as Map<String, dynamic>,
            ),
      now: json['now'] as num?,
    );

Map<String, dynamic> _$AdminAuditResponseToJson(AdminAuditResponse instance) =>
    <String, dynamic>{
      'events': instance.events,
      'total': instance.total,
      'nextBefore': instance.nextBefore,
      'enabled': instance.enabled,
      'ip_mode': instance.ipMode,
      'retention': instance.retention,
      'now': instance.now,
    };
