import 'package:flutter/foundation.dart';

import 'actions/notification_action.dart';
import 'credential_status_notification.dart';
import 'notification_translated_content.dart';

abstract class Notification {
  String id = UniqueKey().toString();
  bool softDeleted = false;
  bool read = false;

  late NotificationTranslatedContent content;
  late NotificationAction? action;
  late DateTime timestamp;

  Map<String, dynamic> toJson();

  Notification();

  // Implement a factory method to create the correct notification type based on the JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    if (json['notificationType'] == 'credentialStatusNotification') {
      return CredentialStatusNotification.fromJson(json);
    }
    throw Exception('Cannot create notification from this JSON');
  }
}
