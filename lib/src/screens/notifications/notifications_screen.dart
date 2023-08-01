import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_dismissible.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/translated_text.dart';
import '../data/credentials_detail_screen.dart';
import 'bloc/notifications_bloc.dart';
import 'models/actions/credential_detail_navigation_action.dart';
import 'models/notification.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

      _notificationsBloc.add(
        MarkNotificationAsRead(notification.id),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CredentialsDetailScreen(
            categoryName: translatedAttributeType,
            credentialTypeId: action.credentialTypeId,
          ),
        ),
      );
    }
  }

  void _onNotificationDismiss(Notification notification) => _notificationsBloc.add(
        SoftDeleteNotification(notification.id),
      );

  Widget _emptyListIndicator(IrmaThemeData theme) => Padding(
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

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

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
                return _emptyListIndicator(theme);
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
