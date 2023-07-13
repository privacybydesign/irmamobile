import 'package:flutter/material.dart' hide Notification;

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import 'models/credential_status_notification.dart';
import 'models/notification.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final List<Notification> notifications = [
      CredentialStatusNotification(
        credentialHash: '21',
        type: CredentialStatusNotificationType.expiringSoon,
        credentialTypeId: 'irma-demo.chipsoft.bsn',
      ),
      CredentialStatusNotification(
        credentialHash: '22',
        type: CredentialStatusNotificationType.revoked,
        credentialTypeId: 'irma-demo.chipsoft.bsn',
      ),
      CredentialStatusNotification(
        credentialHash: '23',
        type: CredentialStatusNotificationType.expired,
        credentialTypeId: 'irma-demo.chipsoft.bsn',
      ),
    ];

    void _onNotificationTap(Notification notification) {
      // TODO: Implement action handler
    }

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'notifications.title',
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.all(
            theme.defaultSpacing,
          ),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];

            return NotificationCard(
              notification: notification,
              onTap: () => _onNotificationTap(notification),
            );
          },
        ),
      ),
    );
  }
}
