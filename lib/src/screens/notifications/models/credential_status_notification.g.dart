// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_status_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialStatusNotification _$CredentialStatusNotificationFromJson(Map<String, dynamic> json) =>
    CredentialStatusNotification(
      credentialHash: json['credentialHash'] as String,
      type: $enumDecode(_$CredentialStatusNotificationTypeEnumMap, json['type']),
      credentialTypeId: json['credentialTypeId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    )
      ..id = json['id'] as String
      ..softDeleted = json['softDeleted'] as bool
      ..read = json['read'] as bool
      ..content = NotificationTranslatedContent.fromJson(json['content'] as Map<String, dynamic>);

Map<String, dynamic> _$CredentialStatusNotificationToJson(CredentialStatusNotification instance) => <String, dynamic>{
      'id': instance.id,
      'softDeleted': instance.softDeleted,
      'read': instance.read,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'credentialHash': instance.credentialHash,
      'type': _$CredentialStatusNotificationTypeEnumMap[instance.type]!,
      'credentialTypeId': instance.credentialTypeId,
    };

const _$CredentialStatusNotificationTypeEnumMap = {
  CredentialStatusNotificationType.revoked: 'revoked',
  CredentialStatusNotificationType.expired: 'expired',
  CredentialStatusNotificationType.expiringSoon: 'expiringSoon',
};
