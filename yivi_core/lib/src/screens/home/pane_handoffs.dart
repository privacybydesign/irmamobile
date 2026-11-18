import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/wallet_cards_provider.dart";
import "../../routing/pane_handoff.dart";
import "../../util/adaptive_layout.dart";
import "../data/wallet/wallet_transition.dart";
import "widgets/home_tab.dart";

// What the home tabs' pages hand to a detail pane when the phone turns
// sideways (PaneHandoff). Turned upright the home screen just shows the
// list: a pane's pick never opens a page of its own.

/// A card on its own screen, opened from Data or Notifications: in the
/// pane of the tab it was opened from.
Widget cardHandoff(BuildContext context, String hash, Widget child) {
  final fromNotifications =
      ProviderScope.containerOf(context, listen: false).read(homeTabProvider) ==
      HomeTab.notifications;
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      // The page may show a sibling of the card it opened with.
      final cards = container.read(walletCardsProvider);
      final open = WalletTransition.openKey.value;
      final shown = cards.any((c) => c.hash == open) ? open! : hash;
      if (fromNotifications) {
        container.read(selectedNotificationCardProvider.notifier).select(shown);
        container.read(selectedNotificationProvider.notifier).select(null);
      } else {
        container.read(homeTabProvider.notifier).select(HomeTab.data);
        container.read(selectedCardProvider.notifier).select(shown);
      }
    },
    child: child,
  );
}

/// An activity entry on its own screen: in the Activity tab's pane.
Widget activityHandoff(BuildContext context, LogInfo log, Widget child) {
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      container.read(homeTabProvider.notifier).select(HomeTab.activity);
      container.read(selectedActivityProvider.notifier).select(log);
    },
    child: child,
  );
}

/// Instellingen or Veelgestelde vragen on their own screen: in the More
/// tab's pane, on a tablet and on a phone held sideways.
Widget morePageHandoff(BuildContext context, MorePage page, Widget child) {
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      container.read(homeTabProvider.notifier).select(HomeTab.more);
      container.read(selectedMorePageProvider.notifier).select(page);
    },
    child: child,
  );
}
