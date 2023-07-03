import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'credential_status_notification.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final UniqueKey key;
  final String title;
  final String message;

  Notification({
    required this.title,
    required this.message,
  }) : key = UniqueKey();

  static Notification fromCredentialStatusNotification(CredentialStatusNotification credStatusNotification) {
    // TODO: Make this dynamic
    return Notification(
      title: 'Credential revoked',
      message: 'The credential ${credStatusNotification.credentialHash} has been revoked',
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}
