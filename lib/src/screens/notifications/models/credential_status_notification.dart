import 'package:json_annotation/json_annotation.dart';

import '../../../models/translated_value.dart';
import 'notification.dart';

part 'credential_status_notification.g.dart';

enum CredentialStatusNotificationType {
  revoked,
  expired,
  expiringSoon,
}

@JsonSerializable()
class CredentialStatusNotification extends Notification {
  final int credentialHash;
  final CredentialStatusNotificationType type;

  CredentialStatusNotification({
    required this.credentialHash,
    required this.type,
  });

  @override
  NotificationAction get action => throw UnimplementedError();

  @override
  TranslatedValue get message {
    // TODO: Use the locales from the app
    const translationValue = TranslatedValue({
      'en': 'Credential is revoked',
      'nl': 'Credential is ingetrokken',
    });

    return translationValue;
  }

  @override
  TranslatedValue get title {
    const translationValue = TranslatedValue({
      'en': 'Credential revoked',
      'nl': 'Credential ingetrokken',
    });

    return translationValue;
  }

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
