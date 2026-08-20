import "package:json_annotation/json_annotation.dart";

import "credential_status_notification.dart";

part "credential_status_notification_record.g.dart";

/// Persisted user-state for a credential-status notification, keyed by
/// `(credentialHash, type)`. Display data is derived from the live credential
/// at render time and never persisted.
@JsonSerializable()
class CredentialStatusNotificationRecord {
  final String credentialHash;
  final CredentialStatusNotificationType type;
  final String id;
  final bool read;
  final bool softDeleted;
  final DateTime timestamp;

  CredentialStatusNotificationRecord({
    required this.credentialHash,
    required this.type,
    required this.id,
    required this.read,
    required this.softDeleted,
    required this.timestamp,
  });

  CredentialStatusNotificationRecord copyWith({bool? read, bool? softDeleted}) {
    return CredentialStatusNotificationRecord(
      credentialHash: credentialHash,
      type: type,
      id: id,
      read: read ?? this.read,
      softDeleted: softDeleted ?? this.softDeleted,
      timestamp: timestamp,
    );
  }

  factory CredentialStatusNotificationRecord.fromJson(
    Map<String, dynamic> json,
  ) => _$CredentialStatusNotificationRecordFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CredentialStatusNotificationRecordToJson(this);
}
