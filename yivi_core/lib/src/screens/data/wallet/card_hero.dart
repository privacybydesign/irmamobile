import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../card_transition/card_transition.dart";
import "wallet_transition.dart";

/// A card picture that flies between the data tab's list or grid (or a
/// notification) and the card detail view. While flying it is redrawn at
/// every size, so it stays sharp and keeps its corners. Cards in the stack
/// do not fly as a hero: they move in place ([CardTransitions]).
class CardHero extends StatelessWidget {
  final schemaless.Credential credential;
  final double width;
  final String? hintText;

  const CardHero({
    super.key,
    required this.credential,
    required this.width,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: WalletTransition.heroTag(credential.hash),
      // The rect tween eases (WalletTransition.rectTween), as everything
      // else that moves with the card: no second curve on top, or the card
      // starts late and the cards above it run ahead.
      curve: Curves.linear,
      reverseCurve: Curves.linear,
      createRectTween: WalletTransition.rectTween,
      // Its place is empty only while the card is open (or flying): Flutter
      // keeps the place of a hero that flew away empty until a flight back
      // lands there. Closed while the Data tab is not shown ("See all"
      // switches to Activity first), no flight comes back, and the place
      // would stay empty, a gap in the list.
      placeholderBuilder: (context, size, child) =>
          ValueListenableBuilder<String?>(
            valueListenable: WalletTransition.openKey,
            builder: (context, open, child) => open == credential.hash
                ? SizedBox.fromSize(size: size)
                : child!,
            child: child,
          ),
      flightShuttleBuilder: (_, _, _, _, _) => LayoutBuilder(
        builder: (context, constraints) => CredentialCardArt(
          credential: credential,
          width: constraints.maxWidth,
          hintText: hintText,
        ),
      ),
      child: CredentialCardArt(
        credential: credential,
        width: width,
        hintText: hintText,
      ),
    );
  }
}
