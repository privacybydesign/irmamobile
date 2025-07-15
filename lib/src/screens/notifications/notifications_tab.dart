import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_dismissible.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/translated_text.dart';
import 'bloc/notifications_bloc.dart';
import 'models/actions/credential_detail_navigation_action.dart';
import 'models/notification.dart';
import 'widgets/notification_card.dart';

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
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    if (action != null && action is CredentialDetailNavigationAction) {
      final repo = IrmaRepositoryProvider.of(context);
      final credType = repo.irmaConfiguration.credentialTypes[action.credentialTypeId]!;
      final translatedAttributeType = credType.name.translate(lang);

      _notificationsBloc.add(MarkNotificationAsRead(notification.id));

      context.pushCredentialsDetailsScreen(
        CredentialsDetailsRouteParams(categoryName: translatedAttributeType, credentialTypeId: action.credentialTypeId),
      );
    }
  }

  void _onNotificationDismiss(Notification notification) {
    _notificationsBloc.add(SoftDeleteNotification(notification.id));
  }

  Widget _emptyListIndicator(IrmaThemeData theme) =>
      // It needs to be wrapped in a ListView because of the RefreshIndicator
      ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Flexible(child: TranslatedText('notifications.empty', textAlign: TextAlign.center))],
            ),
          ),
        ],
      );

  void _onRefresh() {
    _notificationsBloc.add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return BlocProvider.value(
      value: BlocProvider.of<NotificationsBloc>(context),
      child: Scaffold(
        backgroundColor: theme.backgroundTertiary,
        appBar: const IrmaAppBar(titleTranslationKey: 'notifications.title', leading: null),
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
                      ? _emptyListIndicator(theme)
                      : ListView.builder(
                          padding: EdgeInsets.all(theme.defaultSpacing),
                          itemCount: state.notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];

                            return IrmaDismissible(
                              key: Key(notification.id),
                              onDismissed: () => _onNotificationDismiss(notification),
                              child: NotificationCard(
                                notification: notification,
                                onTap: () => _onNotificationTap(notification),
                              ),
                            );
                          },
                        ),
                );
              }

              throw Exception('NotificationsScreen does not support this state: $state');
            },
          ),
        ),
      ),
    );
  }
}
