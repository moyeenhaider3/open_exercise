// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_response_retention.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAuditResponseRetention _$AdminAuditResponseRetentionFromJson(
  Map<String, dynamic> json,
) => AdminAuditResponseRetention(
  max: (json['max'] as num?)?.toInt(),
  days: (json['days'] as num?)?.toInt(),
);

Map<String, dynamic> _$AdminAuditResponseRetentionToJson(
  AdminAuditResponseRetention instance,
) => <String, dynamic>{'max': instance.max, 'days': instance.days};
