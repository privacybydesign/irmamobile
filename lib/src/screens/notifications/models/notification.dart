import 'package:flutter/material.dart';

import '../../../models/translated_value.dart';
import 'credential_status_notification.dart';

abstract class NotificationAction {}

abstract class Notification {
  String id = UniqueKey().toString();
  bool softDeleted = false;

  TranslatedValue get title;
  TranslatedValue get message;
  NotificationAction? get action;

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
