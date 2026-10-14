import "package:collection/collection.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart" hide Notification;

import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_dismissible.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../data/credential_detail/credential_detail_screen.dart";
import "../data/wallet/wallet_transition.dart";
import "bloc/notifications_bloc.dart";
import "models/actions/credential_detail_navigation_action.dart";
import "models/credential_status_notification.dart";
import "models/notification.dart";
import "widgets/notification_card.dart";

class NotificationsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
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

  void _onNotificationTap(
    Notification notification,
    BuildContext pictureContext,
  ) {
    final action = notification.action;
    if (action == null || action is! CredentialDetailNavigationAction) return;
    _notificationsBloc.add(MarkNotificationAsRead(notification.id));

    // Open the card itself when it is still in the wallet.
    if (notification is CredentialStatusNotification) {
      final cards =
          ref.read(schemalessCredentialOrderControllerProvider).value ??
          const [];
      final card = cards.firstWhereOrNull(
        (c) => c.hash == notification.credentialHash,
      );
      if (card != null && isExpandedLayout(context)) {
        ref.read(selectedNotificationCardProvider.notifier).select(card.hash);
        return;
      }
      if (card != null) {
        WalletTransition.begin(pictureContext, card.hash);
        pictureContext.pushCredentialDetailScreen(card.hash);
        return;
      }
    }
    context.pushCredentialsDetailsScreen(
      CredentialsDetailsRouteParams(credentialTypeId: action.credentialTypeId),
    );
  }

  /// The tablet layout: the notifications next to the card the picked one
  /// is about (that of the newest notification until the user picks one).
  Widget _withDetailPane(Widget list, List<Notification> notifications) {
    final palette = YiviPalette.of(context);
    final cards =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const [];
    bool inWallet(String? hash) => cards.any((c) => c.hash == hash);
    final selected = ref.watch(selectedNotificationCardProvider);
    final hash = inWallet(selected)
        ? selected
        : notifications
              .whereType<CredentialStatusNotification>()
              .map((n) => n.credentialHash)
              .firstWhereOrNull(inWallet);
    final selection = ref.read(selectedNotificationCardProvider.notifier);
    return TwoPane(
      list: list,
      detail: hash == null
          ? null
          : CredentialDetailPane(
              key: ValueKey(hash),
              hash: hash,
              onSwitch: selection.select,
              onDeleted: () => selection.select(null),
            ),
      placeholder: Center(
        child: Icon(
          Icons.notifications_none_rounded,
          size: 64,
          color: palette.faint,
        ),
      ),
    );
  }

  void _onNotificationDismiss(Notification notification) {
    _notificationsBloc.add(SoftDeleteNotification(notification.id));
  }

  void _onRefresh() {
    _notificationsBloc.add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    return BlocProvider.value(
      value: BlocProvider.of<NotificationsBloc>(context),
      child: Scaffold(
        backgroundColor: palette.background,
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return Center(child: LoadingIndicator());
            } else if (state is NotificationsLoaded) {
              final notifications = state.notifications;
              final unread = notifications.where((n) => !n.read).length;

              final list = RefreshIndicator(
                edgeOffset: padding.top,
                onRefresh: () => Future.sync(_onRefresh),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    padding.top + 24,
                    16,
                    padding.bottom + bottomBarSpace(context),
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: TranslatedText(
                                        "notifications.title",
                                        style: palette.display(
                                          26,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (unread > 0)
                                    Text(
                                      FlutterI18n.translate(
                                        context,
                                        "notifications.new_count",
                                        translationParams: {"count": "$unread"},
                                      ),
                                      style: palette
                                          .body(14)
                                          .copyWith(color: palette.heading),
                                    ),
                                ],
                              ),
                            ),
                            if (notifications.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: TranslatedText(
                                  "notifications.empty",
                                  textAlign: TextAlign.center,
                                  style: palette
                                      .body(16)
                                      .copyWith(color: palette.heading),
                                ),
                              )
                            else ...[
                              for (final notification in notifications)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: IrmaDismissible(
                                    key: Key(notification.id),
                                    borderRadius: BorderRadius.circular(24),
                                    onDismissed: () =>
                                        _onNotificationDismiss(notification),
                                    child: NotificationCard(
                                      notification: notification,
                                      onTap: (pictureContext) =>
                                          _onNotificationTap(
                                            notification,
                                            pictureContext,
                                          ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TranslatedText(
                                  "notifications.swipe_hint",
                                  textAlign: TextAlign.center,
                                  style: palette
                                      .body(12)
                                      .copyWith(color: palette.secondaryText),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return isExpandedLayout(context)
                  ? _withDetailPane(list, notifications)
                  : list;
            }

            throw Exception(
              "NotificationsScreen does not support this state: $state",
            );
          },
        ),
      ),
    );
  }
}
