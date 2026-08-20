// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_status_notification_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialStatusNotificationRecord _$CredentialStatusNotificationRecordFromJson(
  Map<String, dynamic> json,
) => CredentialStatusNotificationRecord(
  credentialHash: json['credentialHash'] as String,
  type: $enumDecode(_$CredentialStatusNotificationTypeEnumMap, json['type']),
  id: json['id'] as String,
  read: json['read'] as bool,
  softDeleted: json['softDeleted'] as bool,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$CredentialStatusNotificationRecordToJson(
  CredentialStatusNotificationRecord instance,
) => <String, dynamic>{
  'credentialHash': instance.credentialHash,
  'type': _$CredentialStatusNotificationTypeEnumMap[instance.type]!,
  'id': instance.id,
  'read': instance.read,
  'softDeleted': instance.softDeleted,
  'timestamp': instance.timestamp.toIso8601String(),
};

const _$CredentialStatusNotificationTypeEnumMap = {
  CredentialStatusNotificationType.revoked: 'revoked',
  CredentialStatusNotificationType.expired: 'expired',
  CredentialStatusNotificationType.expiringSoon: 'expiringSoon',
};
