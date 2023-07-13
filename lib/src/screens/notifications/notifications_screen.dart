import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_dismissible.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/translated_text.dart';
import 'bloc/notifications_bloc.dart';
import 'models/notification.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final bloc = BlocProvider.of<NotificationsBloc>(context);

    void _onNotificationTap(Notification notification) {
      // TODO: Implement action handler
    }

    void _onNotificationDismiss(Notification notification) => bloc.add(
          SoftDeleteNotification(notification.id),
        );

    Widget _emptyListIndicator() => Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Flexible(
                  child: TranslatedText(
                'notifications.empty',
                textAlign: TextAlign.center,
              ))
            ],
          ),
        );

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'notifications.title',
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return Center(
                child: LoadingIndicator(),
              );
            } else if (state is NotificationsLoaded) {
              final notifications = state.notifications;

              if (notifications.isEmpty) {
                return _emptyListIndicator();
              } else {
                return ListView.builder(
                  padding: EdgeInsets.all(
                    theme.defaultSpacing,
                  ),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];

                    return IrmaDismissible(
                      key: Key(notification.id),
                      onDismissed: () => _onNotificationDismiss(notification),
                      child: NotificationCard(
                        notification: notification,
                        onTap: () => _onNotificationTap(notification),
                      ),
                    );
                  },
                );
              }
            }

            throw Exception('NotificationsScreen does not support this state: $state');
          },
        ),
      ),
    );
  }
}
