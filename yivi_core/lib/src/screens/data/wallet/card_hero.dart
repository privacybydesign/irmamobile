import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "wallet_transition.dart";

/// A card picture that flies between the data tab and the card detail view.
/// While flying it is redrawn at every size, so it stays sharp and keeps its
/// corners.
class CardHero extends StatelessWidget {
  final schemaless.Credential credential;
  final double width;
  final String? hintText;

  /// Draws the card's light top edge, as in the stack.
  final bool edge;

  const CardHero({
    super.key,
    required this.credential,
    required this.width,
    this.hintText,
    this.edge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: WalletTransition.heroTag(credential.hash),
      createRectTween: WalletTransition.rectTween,
      // Flies under the card below its place in the stack, not over it.
      flightShuttleBuilder: (_, animation, _, fromContext, toContext) {
        // The edge belongs to the card in the stack: it fades out on the
        // way to the detail page (animation 0 → 1) and back in on the way
        // back (1 → 0).
        bool hasEdge(BuildContext context) =>
            context.findAncestorWidgetOfExactType<CardHero>()?.edge ?? false;
        final edge = hasEdge(fromContext) || hasEdge(toContext);
        return CoveredByStack(
          hash: credential.hash,
          repaint: animation,
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CredentialCardArt(
                credential: credential,
                width: constraints.maxWidth,
                hintText: hintText,
                edge: edge ? 1 - animation.value : 0,
              ),
            ),
          ),
        );
      },
      child: CredentialCardArt(
        credential: credential,
        width: width,
        hintText: hintText,
        edge: edge ? 1 : 0,
      ),
    );
  }
}
