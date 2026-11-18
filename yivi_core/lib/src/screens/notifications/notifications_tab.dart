import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart" hide Notification;

import "../../providers/credential_store_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/wallet_cards_provider.dart";
import "../../routing/navigation.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/adaptive_layout.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/title_scroll_edge.dart";
import "../../widgets/feedback/app_toast.dart";
import "../../widgets/feedback/yivi_spinner.dart";
import "../../widgets/layout/centred_max_width.dart";
import "../../widgets/layout/tab_layout.dart";
import "../../widgets/layout/two_pane.dart";
import "../../widgets/text/translated_text.dart";
import "../add_data/add_data_sheet.dart";
import "../data/credential_detail/credential_detail_screen.dart";
import "../data/wallet/wallet_transition.dart";
import "models/credential_status_notification.dart";
import "models/notification.dart";
import "notifications_provider.dart";
import "widgets/no_notifications.dart";
import "widgets/notification_card.dart";
import "widgets/yivi_dismissible.dart";

class NotificationsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  void _onNotificationTap(
    Notification notification,
    BuildContext pictureContext,
  ) {
    if (notification is! CredentialStatusNotification) return;
    ref.read(notificationsProvider.notifier).markRead(notification.id);

    // The card itself when it is still in the wallet, else another card of
    // its type, else Add data on the type.
    final cards = ref.read(walletCardsProvider);
    final card =
        cards.firstWhereOrNull((c) => c.hash == notification.credentialHash) ??
        cards.firstWhereOrNull(
          (c) => c.credentialId == notification.credentialTypeId,
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
    _addAgain(notification.credentialTypeId);
  }

  /// No card of the type is left: Add data, on the type, when the store
  /// still offers it; else a toast says so.
  Future<void> _addAgain(String credentialTypeId) async {
    final toast = appToastFor(context, overTabBar: true);
    // Listened to while waiting, so the store stays loaded until it is there.
    final subscription = ref.listenManual(
      groupedCredentialStoreProvider,
      (_, _) {},
    );
    List<CredentialStoreCategory> store = const [];
    try {
      store = await ref.read(groupedCredentialStoreProvider.future);
    } catch (_) {
      // Without the store there is nothing to add it from.
    } finally {
      subscription.close();
    }
    if (!mounted) return;
    final descriptor = store
        .expand((group) => group.items)
        .map((item) => item.credential)
        .firstWhereOrNull((c) => c.credentialId == credentialTypeId);
    if (descriptor == null) {
      toast(context.tr("notifications.card_gone"));
      return;
    }
    showAddDataSheet(context, addNew: descriptor, flyToDataTab: false);
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
  String? _paneNotificationId(List<Notification> notifications, String? hash) {
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
  Widget _withDetailPane(Widget list, String? hash) {
    final palette = YiviPalette.of(context);
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
    ref.read(notificationsProvider.notifier).dismiss(notification.id);
  }

  void _onRefresh() {
    ref.read(notificationsProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: TitleScrollEdge(
        title: context.tr("notifications.title"),
        largeTitleBottom: tabTitleBottom,
        child: Builder(
          builder: (context) {
            final state = ref.watch(notificationsProvider);
            if (state is NotificationsLoading) {
              return Center(child: YiviSpinner());
            } else if (state is NotificationsLoaded) {
              final notifications = state.notifications;
              final unread = state.unreadCount;
              final panes = useHomePanes(context);
              final paneHash = panes ? _paneHash(notifications) : null;
              final openId = panes
                  ? _paneNotificationId(notifications, paneHash)
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
                            padding: const EdgeInsets.only(
                              bottom: YiviSpace.x16,
                            ),
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
                                    context.tr("notifications.new_count", {
                                      "count": "$unread",
                                    }),
                                    style: palette
                                        .body(14)
                                        .copyWith(color: palette.heading),
                                  ),
                              ],
                            ),
                          ),
                          if (notifications.isEmpty)
                            const NoNotifications()
                          else ...[
                            for (final notification in notifications)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: YiviSpace.x8,
                                ),
                                child: YiviDismissible(
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
                              padding: const EdgeInsets.only(top: YiviSpace.x8),
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
              return panes ? _withDetailPane(list, paneHash) : list;
            }

            throw Exception(
              "NotificationsTab does not support this state: $state",
            );
          },
        ),
      ),
    );
  }
}
