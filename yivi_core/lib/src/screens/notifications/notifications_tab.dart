import "package:collection/collection.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart" hide Notification;

import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/navigation.dart";
import "../../widgets/centred_max_width.dart";
import "../../widgets/empty_list_message.dart";
import "../../widgets/glass/title_scroll_edge.dart";
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
      final cards = ref.read(walletCardsProvider);
      final card = cards.firstWhereOrNull(
        (c) => c.hash == notification.credentialHash,
      );
      if (card != null && useHomePanes(context)) {
        ref.read(selectedNotificationCardProvider.notifier).select(card.hash);
        ref.read(selectedNotificationProvider.notifier).select(notification.id);
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

  /// The card the detail pane shows: the picked one, or that of the newest
  /// notification about a card in the wallet.
  String? _paneHash(List<Notification> notifications) {
    final cards = ref.watch(walletCardsProvider);
    bool inWallet(String? hash) => cards.any((c) => c.hash == hash);
    final selected = ref.watch(selectedNotificationCardProvider);
    return inWallet(selected)
        ? selected
        : notifications
              .whereType<CredentialStatusNotification>()
              .map((n) => n.credentialHash)
              .firstWhereOrNull(inWallet);
  }

  /// The notification whose card the detail pane shows: the one picked,
  /// else the first about that card.
  String? _paneNotificationId(List<Notification> notifications) {
    final hash = _paneHash(notifications);
    if (hash == null) return null;
    bool about(Notification n) =>
        n is CredentialStatusNotification && n.credentialHash == hash;
    final picked = ref.watch(selectedNotificationProvider);
    final match =
        notifications.firstWhereOrNull((n) => n.id == picked && about(n)) ??
        notifications.firstWhereOrNull(about);
    return match?.id;
  }

  /// The tablet layout: the notifications next to the card the picked one
  /// is about (that of the newest notification until the user picks one).
  Widget _withDetailPane(Widget list, List<Notification> notifications) {
    final palette = YiviPalette.of(context);
    final hash = _paneHash(notifications);
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
        body: TitleScrollEdge(
          title: FlutterI18n.translate(context, "notifications.title"),
          largeTitleBottom: tabTitleBottom,
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return Center(child: LoadingIndicator());
              } else if (state is NotificationsLoaded) {
                final notifications = state.notifications;
                final unread = notifications.where((n) => !n.read).length;
                final openId = useHomePanes(context)
                    ? _paneNotificationId(notifications)
                    : null;

                final list = RefreshIndicator(
                  edgeOffset: padding.top,
                  onRefresh: () => Future.sync(_onRefresh),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: tabPagePadding(context),
                    children: [
                      CentredMaxWidth(
                        maxWidth: mediumContentMaxWidth,
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
                                    child: const TabLargeTitle(
                                      "notifications.title",
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
                              const EmptyListMessage(
                                "notifications.empty",
                                top: 48,
                              )
                            else ...[
                              for (final notification in notifications)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: IrmaDismissible(
                                    key: Key(notification.id),
                                    borderRadius: YiviCorners.cardRadius,
                                    onDismissed: () =>
                                        _onNotificationDismiss(notification),
                                    child: NotificationCard(
                                      notification: notification,
                                      selected: notification.id == openId,
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
                    ],
                  ),
                );
                return useHomePanes(context)
                    ? _withDetailPane(list, notifications)
                    : list;
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
