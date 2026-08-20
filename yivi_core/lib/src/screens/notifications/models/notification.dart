import "package:flutter/foundation.dart";

import "actions/notification_action.dart";
import "notification_translated_content.dart";

abstract class Notification {
  String id = UniqueKey().toString();
  bool softDeleted = false;
  bool read = false;

  late NotificationTranslatedContent content;
  late NotificationAction? action;
  late DateTime timestamp;

  Notification();
}
