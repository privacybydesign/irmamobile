import 'credential_detail_navigation_action.dart';

abstract class NotificationAction {
  Map<String, dynamic> toJson();

  NotificationAction();

  // Implement a factory method to create the correct notification type based on the JSON
  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    if (json['notificationType'] == 'credentialDetailNavigationAction') {
      return CredentialDetailNavigationAction.fromJson(json);
    }
    throw Exception('Cannot create notification action from this JSON');
  }
}
