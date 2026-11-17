import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "activity_providers.dart";
import "wallet_cards_provider.dart";

/// What the detail pane of a tablet layout shows. Null means nothing was
/// picked yet; each tab then picks its own default.
class PaneSelection<T> extends Notifier<T?> {
  @override
  T? build() => null;

  void select(T? value) => state = value;
}

/// The card (credential instance hash) open in the data tab's detail pane.
final selectedCardProvider = NotifierProvider<PaneSelection<String>, String?>(
  PaneSelection<String>.new,
);

/// The field a search found the card [hash] by (its claim path key): the
/// card opens on it. Kept for a card that opens in the detail pane, or moves
/// there when the phone is turned; another card ignores it.
final foundCardFieldProvider =
    NotifierProvider<
      PaneSelection<({String hash, String claimKey})>,
      ({String hash, String claimKey})?
    >(PaneSelection<({String hash, String claimKey})>.new);

/// The log entry open in the activity tab's detail pane.
final selectedActivityProvider =
    NotifierProvider<PaneSelection<LogInfo>, LogInfo?>(
      PaneSelection<LogInfo>.new,
    );

/// The card open in the notifications tab's detail pane.
final selectedNotificationCardProvider =
    NotifierProvider<PaneSelection<String>, String?>(PaneSelection<String>.new);

/// The notification (its id) that was picked to open its card in the
/// notifications tab's detail pane; its row is the one marked.
final selectedNotificationProvider =
    NotifierProvider<PaneSelection<String>, String?>(PaneSelection<String>.new);

/// The pages of the More tab that open in its detail pane (a phone held
/// sideways).
enum MorePage { settings, faq }

/// The page open in the More tab's detail pane; null: Instellingen.
final selectedMorePageProvider =
    NotifierProvider<PaneSelection<MorePage>, MorePage?>(
      PaneSelection<MorePage>.new,
    );

/// The card the Data tab's detail pane shows: the picked one while it is
/// in the app, else the first.
final dataPaneCardProvider = Provider<String?>((ref) {
  final cards = ref.watch(walletCardsProvider);
  final selected = ref.watch(selectedCardProvider);
  return cards.any((c) => c.hash == selected)
      ? selected
      : cards.firstOrNull?.hash;
});

/// The entry the Activity tab's detail pane shows: the picked one, else the
/// newest loaded.
final activityPaneEntryProvider = Provider<LogInfo?>(
  (ref) =>
      ref.watch(selectedActivityProvider) ??
      ref.watch(activityLogProvider).entries.firstOrNull,
);
