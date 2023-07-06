import 'package:collection/collection.dart';

import '../../../data/irma_repository.dart';
import '../../../widgets/credential_card/models/card_expiry_date.dart';
import '../models/credential_status_notification.dart';
import '../models/notification.dart';
import 'notification_handler.dart';

class CredentialStatusNotificationsHandler extends NotificationHandler {
  @override
  Future<List<Notification>> loadNotifications(IrmaRepository repo, List<Notification> notifications) async {
    final List<Notification> updatedNotifications = notifications;

    for (final cred in repo.credentials.values) {
      // Check if a notification should be shown for this credential, and if so which type
      CredentialStatusNotificationType? notificationType;

      if (cred.revoked) {
        notificationType = CredentialStatusNotificationType.revoked;
      } else if (cred.expired) {
        notificationType = CredentialStatusNotificationType.expired;
      } else if (CardExpiryDate(cred.expires).expiresSoon) {
        notificationType = CredentialStatusNotificationType.expiringSoon;
      }

      // If a notification should be shown for this credential..
      if (notificationType != null) {
        bool shouldAddNewNotification = true;

        // Check if there is already a notification for this credential
        final CredentialStatusNotification? existingNotification =
            updatedNotifications.firstWhereOrNull((notification) {
          if (notification is CredentialStatusNotification) {
            return notification.credentialHash == cred.hashCode;
          }

          return false;
        }) as CredentialStatusNotification?;

        if (existingNotification != null) {
          // If the existing has a different type, remove the old one and add a new one later
          if (existingNotification.type != notificationType) {
            updatedNotifications.remove(existingNotification);
          } else {
            // If the existing has the same type, don't add a new one
            shouldAddNewNotification = false;
          }
        }

        if (shouldAddNewNotification) {
          updatedNotifications.add(
            CredentialStatusNotification(
              type: notificationType,
              credentialHash: cred.hashCode,
              credentialTypeId: cred.credentialType.fullId,
            ),
          );
        }
      }
    }

    return updatedNotifications;
  }
}
