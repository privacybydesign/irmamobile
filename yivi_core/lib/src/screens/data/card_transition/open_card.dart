import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../providers/pane_selection_provider.dart";
import "../../../providers/search_query_provider.dart";
import "../../../routing/navigation.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../credential_detail/credential_detail_screen.dart";
import "../wallet/wallet_transition.dart";
import "card_origin.dart";
import "card_slots.dart";
import "card_transition.dart";
import "card_transition_layer.dart";
import "choreography.dart";

/// Opens [credential]'s details from where it is on screen ([from], the
/// tapped card). Next to a pane the card is selected in it instead.
/// One at a time: a tap while one is busy does nothing.
/// [found]: the field (a claim path key) a search found it by; it opens on
/// that field.
void openCard(
  BuildContext from,
  Credential credential, {
  required CardOrigin origin,
  String? found,
}) {
  final container = ProviderScope.containerOf(from, listen: false);
  container
      .read(foundCardFieldProvider.notifier)
      .select(found == null ? null : (hash: credential.hash, claimKey: found));
  if (useHomePanes(from)) {
    // The tablet and landscape layouts show the card in the detail pane
    // next to the list.
    container.read(selectedCardProvider.notifier).select(credential.hash);
    return;
  }
  // Opened while typing in the search (the keyboard is still on its way
  // down): it comes back with the search when the card closes.
  container
      .read(dataSearchProvider.notifier)
      .cardOpened(keyboardUp: View.of(from).viewInsets.bottom > 0);
  final transitions = CardTransitionScope.maybeOf(from);
  if (transitions != null && transitions.busy) return;
  if (transitions != null &&
      origin.isStack &&
      !MediaQuery.disableAnimationsOf(from) &&
      _openWithTransition(from, transitions, credential, origin, found)) {
    return;
  }
  WalletTransition.begin(from, credential.hash);
  from.pushCredentialDetailScreen(credential.hash, found: found);
}

/// What a card's transition measures when it opens from [origin]: its
/// picture (or the whole stack) and where it goes on the details. Null when
/// it is not laid out.
TransitionSnapshot? cardSnapshot(
  BuildContext context, {
  required CardOrigin origin,
  required String hash,
}) {
  final slots = CardSlots.of(context);
  final List<Rect> cards;
  final int picked;
  if (origin.isStack) {
    final stack = slots.stack();
    if (stack == null) return null;
    picked = stack.hashes.indexOf(hash);
    if (picked < 0) return null;
    cards = stack.rects;
  } else {
    final rect = slots.rectOf(hash, origin.view);
    if (rect == null) return null;
    picked = 0;
    cards = [rect];
  }
  final screen = MediaQuery.sizeOf(context);
  final width = min(
    screen.width - 32,
    OpenCardLayer.detailsMaxWidth,
  ).toDouble();
  return TransitionSnapshot(
    origin: origin,
    hash: hash,
    picked: picked,
    cards: cards,
    target: Rect.fromLTWH(
      (screen.width - width) / 2,
      MediaQuery.paddingOf(context).top + YiviAppBar.contentTop,
      width,
      width / CredentialCardArt.aspectRatio,
    ),
    screenHeight: screen.height,
  );
}

bool _openWithTransition(
  BuildContext from,
  CardTransitionsState transitions,
  Credential credential,
  CardOrigin origin,
  String? found,
) {
  final snapshot = cardSnapshot(from, origin: origin, hash: credential.hash);
  if (snapshot == null) return false;
  final slots = CardSlots.of(from);
  return transitions.open(
    snapshot: snapshot,
    list: Scrollable.maybeOf(from)?.position,
    measure: (hash) => slots.rectOf(hash, origin.view),
    details: (context, transition) => CredentialDetailScreen(
      hash: credential.hash,
      found: found,
      transition: transition,
    ),
  );
}
