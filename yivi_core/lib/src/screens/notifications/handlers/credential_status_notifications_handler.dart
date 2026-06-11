import "package:collection/collection.dart";
import "package:flutter/foundation.dart";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../widgets/credential_card/models/card_expiry_date.dart";
import "../models/credential_status_notification.dart";
import "../models/credential_status_notification_record.dart";
import "../models/notification.dart";
import "notification_handler.dart";

class CredentialStatusNotificationsHandler extends NotificationHandler {
  @override
  Future<HandlerResult> load(
    IrmaRepository repo,
    List<CredentialStatusNotificationRecord> records,
  ) async {
    final credentials = await repo.getSchemalessCredentials().first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );

    final List<Notification> notifications = [];
    final List<CredentialStatusNotificationRecord> updatedRecords = [];

    for (final cred in credentials) {
      final type = _getNotificationType(cred);
      if (type == null) continue;

      final existing = records.firstWhereOrNull(
        (r) => r.credentialHash == cred.hash && r.type == type,
      );

      final record =
          existing ??
          CredentialStatusNotificationRecord(
            credentialHash: cred.hash,
            type: type,
            id: UniqueKey().toString(),
            read: false,
            softDeleted: false,
            timestamp: DateTime.now(),
          );

      updatedRecords.add(record);
      notifications.add(
        CredentialStatusNotification.fromRecord(
          record: record,
          credentialTypeId: cred.credentialId,
          credentialName: cred.name,
          issuerName: cred.issuer.name,
          logoImage: cred.image,
        ),
      );
    }

    return HandlerResult(
      notifications: notifications,
      updatedRecords: updatedRecords,
    );
  }

  CredentialStatusNotificationType? _getNotificationType(
    schemaless.Credential cred,
  ) {
    if (cred.revoked) {
      return CredentialStatusNotificationType.revoked;
    }
    
    if (cred.expiryDate != null) {
      final expiryDate = CardExpiryDate.fromUnix(cred.expiryDate!);
      if (expiryDate.expired) {
        return CredentialStatusNotificationType.expired;
      }
      if (expiryDate.expiresSoon) {
        return CredentialStatusNotificationType.expiringSoon;
      }
    }
    return null;
  }
}
