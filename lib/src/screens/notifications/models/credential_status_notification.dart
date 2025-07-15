import 'package:json_annotation/json_annotation.dart';

import 'actions/credential_detail_navigation_action.dart';
import 'actions/notification_action.dart';
import 'notification.dart';
import 'notification_translated_content.dart';

part 'credential_status_notification.g.dart';

enum CredentialStatusNotificationType {
  revoked,
  expired,
  expiringSoon,
}

@JsonSerializable()
class CredentialStatusNotification extends Notification {
  final String credentialHash;
  final CredentialStatusNotificationType type;
  final String credentialTypeId;

  CredentialStatusNotification({
    required this.credentialHash,
    required this.type,
    required this.credentialTypeId,
    required DateTime timestamp,
  }) : super() {
    this.timestamp = timestamp;
    content = _getTranslatedNotificationContent(type);
  }

  InternalTranslatedContent _getTranslatedNotificationContent(CredentialStatusNotificationType type) {
    String typeTranslationKey;
    switch (type) {
      case CredentialStatusNotificationType.revoked:
        typeTranslationKey = 'revoked';
        break;
      case CredentialStatusNotificationType.expired:
        typeTranslationKey = 'expired';
        break;
      case CredentialStatusNotificationType.expiringSoon:
        typeTranslationKey = 'expiring_soon';
        break;
    }

    return InternalTranslatedContent(
      titleTranslationKey: 'notifications.credential_status.$typeTranslationKey.title',
      messageTranslationKey: 'notifications.credential_status.$typeTranslationKey.message',
    );
  }

  @override
  NotificationAction get action => CredentialDetailNavigationAction(
        credentialTypeId: credentialTypeId,
      );

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = _$CredentialStatusNotificationToJson(this);

    // Add the notificationType to the JSON, so we know which type of notification to create when loading from JSON
    jsonMap['notificationType'] = 'credentialStatusNotification';

    return jsonMap;
  }

  factory CredentialStatusNotification.fromJson(Map<String, dynamic> json) =>
      _$CredentialStatusNotificationFromJson(json);
}
