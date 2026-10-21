import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../util/adaptive_layout.dart";
import "../../widgets/pane_handoff.dart";
import "../data/wallet/wallet_transition.dart";
import "home_screen.dart";
import "widgets/irma_nav_bar.dart";

// What the home tabs' pages hand to a detail pane when the phone turns
// sideways (PaneHandoff). Turned upright the home screen just shows the
// list: a pane's pick never opens a page of its own.

/// A card on its own screen, opened from Gegevens or Notificaties: in the
/// pane of the tab it was opened from.
Widget cardHandoff(BuildContext context, String hash, Widget child) {
  final tabs = context.read<HomeTabState>();
  final fromNotifications = tabs.state == IrmaNavBarTab.notifications;
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      // The page may show a sibling of the card it opened with.
      final cards =
          container.read(schemalessCredentialOrderControllerProvider).value ??
          const [];
      final open = WalletTransition.openKey.value;
      final shown = cards.any((c) => c.hash == open) ? open! : hash;
      if (fromNotifications) {
        container.read(selectedNotificationCardProvider.notifier).select(shown);
        container.read(selectedNotificationProvider.notifier).select(null);
      } else {
        tabs.add(IrmaNavBarTab.data);
        container.read(selectedCardProvider.notifier).select(shown);
      }
    },
    child: child,
  );
}

/// An activity entry on its own screen: in the Activity tab's pane.
Widget activityHandoff(BuildContext context, LogInfo log, Widget child) {
  final tabs = context.read<HomeTabState>();
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      tabs.add(IrmaNavBarTab.activity);
      container.read(selectedActivityProvider.notifier).select(log);
    },
    child: child,
  );
}

/// Instellingen or Veelgestelde vragen on their own screen: in the More
/// tab's pane. Only on a phone held sideways; on a tablet they stay sheets.
Widget morePageHandoff(BuildContext context, MorePage page, Widget child) {
  final tabs = context.read<HomeTabState>();
  return PaneHandoff(
    paneAvailable: usePhoneLandscape,
    onHandoff: (container) {
      tabs.add(IrmaNavBarTab.more);
      container.read(selectedMorePageProvider.notifier).select(page);
    },
    child: child,
  );
}
