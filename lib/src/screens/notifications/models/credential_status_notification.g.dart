// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_status_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialStatusNotification _$CredentialStatusNotificationFromJson(Map<String, dynamic> json) =>
    CredentialStatusNotification(
      credentialHash: json['credentialHash'] as int,
      type: $enumDecode(_$CredentialStatusNotificationTypeEnumMap, json['type']),
    )
      ..id = json['id'] as String
      ..softDeleted = json['softDeleted'] as bool;

Map<String, dynamic> _$CredentialStatusNotificationToJson(CredentialStatusNotification instance) => <String, dynamic>{
      'id': instance.id,
      'softDeleted': instance.softDeleted,
      'credentialHash': instance.credentialHash,
      'type': _$CredentialStatusNotificationTypeEnumMap[instance.type]!,
    };

const _$CredentialStatusNotificationTypeEnumMap = {
  CredentialStatusNotificationType.revoked: 'revoked',
  CredentialStatusNotificationType.expired: 'expired',
  CredentialStatusNotificationType.expiringSoon: 'expiringSoon',
};
