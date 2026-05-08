import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/translated_value.dart";
import "actions/credential_detail_navigation_action.dart";
import "actions/notification_action.dart";
import "credential_status_notification_record.dart";
import "notification.dart";
import "notification_translated_content.dart";

enum CredentialStatusNotificationType { revoked, expired, expiringSoon }

/// Runtime-only notification rendered in the UI. Built fresh on every
/// `LoadNotifications` from a live `Credential` plus its persisted
/// `CredentialStatusNotificationRecord`.
class CredentialStatusNotification extends Notification {
  final String credentialHash;
  final CredentialStatusNotificationType type;
  final String credentialTypeId;
  final TranslatedValue credentialName;
  final TranslatedValue issuerName;
  final LogoImage? logoImage;

  CredentialStatusNotification({
    required this.credentialHash,
    required this.type,
    required this.credentialTypeId,
    required this.credentialName,
    required this.issuerName,
    required String id,
    required bool read,
    required bool softDeleted,
    required DateTime timestamp,
    this.logoImage,
  }) : super() {
    this.id = id;
    this.read = read;
    this.softDeleted = softDeleted;
    this.timestamp = timestamp;
    content = _getTranslatedNotificationContent(type);
  }

  /// Builds a runtime notification from a persisted record plus the
  /// denormalized display data sourced from the live credential.
  factory CredentialStatusNotification.fromRecord({
    required CredentialStatusNotificationRecord record,
    required String credentialTypeId,
    required TranslatedValue credentialName,
    required TranslatedValue issuerName,
    LogoImage? logoImage,
  }) => CredentialStatusNotification(
    credentialHash: record.credentialHash,
    type: record.type,
    credentialTypeId: credentialTypeId,
    credentialName: credentialName,
    issuerName: issuerName,
    logoImage: logoImage,
    id: record.id,
    read: record.read,
    softDeleted: record.softDeleted,
    timestamp: record.timestamp,
  );

  InternalTranslatedContent _getTranslatedNotificationContent(
    CredentialStatusNotificationType type,
  ) {
    String typeTranslationKey;
    switch (type) {
      case CredentialStatusNotificationType.revoked:
        typeTranslationKey = "revoked";
        break;
      case CredentialStatusNotificationType.expired:
        typeTranslationKey = "expired";
        break;
      case CredentialStatusNotificationType.expiringSoon:
        typeTranslationKey = "expiring_soon";
        break;
    }

    return InternalTranslatedContent(
      titleTranslationKey:
          "notifications.credential_status.$typeTranslationKey.title",
      messageTranslationKey:
          "notifications.credential_status.$typeTranslationKey.message",
    );
  }

  @override
  NotificationAction get action =>
      CredentialDetailNavigationAction(credentialTypeId: credentialTypeId);
}
