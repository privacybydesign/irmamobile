import "../../../models/credential.dart";
import "credential_status_notification_record.dart";
import "notification.dart";

enum CredentialStatusNotificationType { revoked, expired, expiringSoon }

/// A card that was revoked, has expired or expires soon. Built fresh on every
/// load from a live [Credential] plus its stored
/// [CredentialStatusNotificationRecord].
class CredentialStatusNotification extends Notification {
  @override
  final String id;
  @override
  final bool read;
  @override
  final bool softDeleted;
  @override
  final DateTime timestamp;

  final String credentialHash;
  final CredentialStatusNotificationType type;

  /// The card's type, which a tap opens when the card itself is gone.
  final String credentialTypeId;
  final String credentialName;
  final String issuerName;
  final LogoImage? logoImage;

  const CredentialStatusNotification({
    required this.id,
    required this.read,
    required this.softDeleted,
    required this.timestamp,
    required this.credentialHash,
    required this.type,
    required this.credentialTypeId,
    required this.credentialName,
    required this.issuerName,
    this.logoImage,
  });

  factory CredentialStatusNotification.fromRecord({
    required CredentialStatusNotificationRecord record,
    required String credentialTypeId,
    required String credentialName,
    required String issuerName,
    LogoImage? logoImage,
  }) => CredentialStatusNotification(
    id: record.id,
    read: record.read,
    softDeleted: record.softDeleted,
    timestamp: record.timestamp,
    credentialHash: record.credentialHash,
    type: record.type,
    credentialTypeId: credentialTypeId,
    credentialName: credentialName,
    issuerName: issuerName,
    logoImage: logoImage,
  );

  @override
  CredentialStatusNotification copyWith({bool? read, bool? softDeleted}) =>
      CredentialStatusNotification(
        id: id,
        read: read ?? this.read,
        softDeleted: softDeleted ?? this.softDeleted,
        timestamp: timestamp,
        credentialHash: credentialHash,
        type: type,
        credentialTypeId: credentialTypeId,
        credentialName: credentialName,
        issuerName: issuerName,
        logoImage: logoImage,
      );

  String get _typeKey => switch (type) {
    CredentialStatusNotificationType.revoked => "revoked",
    CredentialStatusNotificationType.expired => "expired",
    CredentialStatusNotificationType.expiringSoon => "expiring_soon",
  };

  @override
  String get titleKey => "notifications.credential_status.$_typeKey.title";

  @override
  String get messageKey => "notifications.credential_status.$_typeKey.message";
}
