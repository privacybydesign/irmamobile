import "package:flutter/material.dart" hide Notification;
import "package:flutter_bloc/flutter_bloc.dart";

import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_dismissible.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/translated_text.dart";
import "bloc/notifications_bloc.dart";
import "models/actions/credential_detail_navigation_action.dart";
import "models/notification.dart";
import "widgets/notification_card.dart";

class NotificationsTab extends StatefulWidget {
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = BlocProvider.of<NotificationsBloc>(context);
  }

  @override
  void dispose() {
    _notificationsBloc.add(MarkAllNotificationsAsRead());
    super.dispose();
  }

  void _onNotificationTap(Notification notification) {
    final action = notification.action;

    if (action != null && action is CredentialDetailNavigationAction) {
      _notificationsBloc.add(MarkNotificationAsRead(notification.id));

      context.pushCredentialsDetailsScreen(
        CredentialsDetailsRouteParams(
          credentialTypeId: action.credentialTypeId,
        ),
      );
    }
  }

  void _onNotificationDismiss(Notification notification) {
    _notificationsBloc.add(SoftDeleteNotification(notification.id));
  }

  Widget _emptyListIndicator() =>
      // It needs to be wrapped in a ListView because of the RefreshIndicator
      ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(context.yivi.defaultSpacing),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: TranslatedText(
                    "notifications.empty",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  void _onRefresh() {
    _notificationsBloc.add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<NotificationsBloc>(context),
      child: Scaffold(
        backgroundColor: context.colors.surfaceContainerHigh,
        appBar: IrmaAppBar(
          titleTranslationKey: "notifications.title",
          leading: null,
        ),
        body: SafeArea(
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return Center(child: LoadingIndicator());
              } else if (state is NotificationsLoaded) {
                final notifications = state.notifications;

                return RefreshIndicator(
                  onRefresh: () => Future.sync(_onRefresh),
                  child: notifications.isEmpty
                      ? _emptyListIndicator()
                      : ListView.builder(
                          padding: EdgeInsets.all(context.yivi.defaultSpacing),
                          itemCount: state.notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: context.yivi.smallSpacing,
                              ),
                              child: IrmaDismissible(
                                key: Key(notification.id),
                                onDismissed: () =>
                                    _onNotificationDismiss(notification),
                                child: NotificationCard(
                                  notification: notification,
                                  onTap: () => _onNotificationTap(notification),
                                ),
                              ),
                            );
                          },
                        ),
                );
              }

              throw Exception(
                "NotificationsScreen does not support this state: $state",
              );
            },
          ),
        ),
      ),
    );
  }
}
