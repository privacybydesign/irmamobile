import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../util/adaptive_layout.dart";
import "../../util/navigation.dart";
import "../../widgets/pane_handoff.dart";
import "../data/wallet/wallet_transition.dart";
import "home_screen.dart";
import "widgets/irma_nav_bar.dart";

// What the home tabs' pages hand to a detail pane when the phone turns
// sideways (PaneHandoff), and what the home screen opens again when it turns
// back upright (HomeLayoutSync).

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
    onClosed: (container) {
      if (fromNotifications) {
        container.read(selectedNotificationCardProvider.notifier).select(null);
        container.read(selectedNotificationProvider.notifier).select(null);
      } else {
        container.read(selectedCardProvider.notifier).select(null);
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
    onClosed: (container) =>
        container.read(selectedActivityProvider.notifier).select(null),
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
    onClosed: (container) =>
        container.read(selectedMorePageProvider.notifier).select(null),
    child: child,
  );
}

/// Opens the item picked in the visible tab's detail pane as its own
/// screen, without a transition: for when the phone turns upright and the
/// pane goes away. Nothing picked (the pane showed its default): nothing
/// opens.
void reopenPickedItem(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final tab = context.read<HomeTabState>().state;
  final cards =
      container.read(schemalessCredentialOrderControllerProvider).value ??
      const [];
  bool inWallet(String? hash) => cards.any((c) => c.hash == hash);

  switch (tab) {
    case IrmaNavBarTab.data:
      final hash = container.read(selectedCardProvider);
      if (inWallet(hash)) {
        RouteMotion.instantly(() => context.pushCredentialDetailScreen(hash!));
      }
    case IrmaNavBarTab.notifications:
      final hash = container.read(selectedNotificationCardProvider);
      if (inWallet(hash)) {
        RouteMotion.instantly(() => context.pushCredentialDetailScreen(hash!));
      }
    case IrmaNavBarTab.activity:
      final log = container.read(selectedActivityProvider);
      if (log != null) {
        RouteMotion.instantly(
          () => context.pushActivityDetailsScreen(logInfo: log),
        );
      }
    case IrmaNavBarTab.more:
      switch (container.read(selectedMorePageProvider)) {
        case MorePage.settings:
          RouteMotion.instantly(context.goSettingsScreen);
        case MorePage.faq:
          RouteMotion.instantly(context.goHelpScreen);
        case null:
          break;
      }
  }
}

/// Keeps the user on what they look at when the home screen's layout gets
/// or loses its detail panes (the phone turns, a split view resizes): when
/// the panes go away, the item picked in the visible tab opens as its own
/// screen. The other way round, a page open on its own screen hands itself
/// to the pane ([PaneHandoff]).
class HomeLayoutSync extends StatefulWidget {
  final Widget child;

  const HomeLayoutSync({super.key, required this.child});

  @override
  State<HomeLayoutSync> createState() => _HomeLayoutSyncState();
}

class _HomeLayoutSyncState extends State<HomeLayoutSync> {
  bool? _panes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final panes = useHomePanes(context);
    final lost = _panes == true && !panes;
    _panes = panes;
    // Only when the home screen is on top: not under a sheet or a page.
    if (lost && (ModalRoute.of(context)?.isCurrent ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !useHomePanes(context)) reopenPickedItem(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
