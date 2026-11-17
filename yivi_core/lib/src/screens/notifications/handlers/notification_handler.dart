import "../../../data/irma_repository.dart";
import "../models/credential_status_notification_record.dart";
import "../models/notification.dart";

class HandlerResult {
  final List<Notification> notifications;
  final List<CredentialStatusNotificationRecord> updatedRecords;

  HandlerResult({
    required List<Notification> notifications,
    required List<CredentialStatusNotificationRecord> updatedRecords,
  }) : notifications = List.unmodifiable(notifications),
       updatedRecords = List.unmodifiable(updatedRecords);
}

abstract class NotificationHandler {
  /// Builds the runtime notifications and the persisted records for this
  /// handler. Records with no matching live data are dropped.
  Future<HandlerResult> load(
    IrmaRepository repo,
    List<CredentialStatusNotificationRecord> records,
  );
}
