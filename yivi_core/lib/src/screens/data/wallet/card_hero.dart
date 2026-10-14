import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "wallet_transition.dart";

/// A card picture that flies between the data tab and the card detail view.
/// While flying it is redrawn at every size, so it stays sharp and keeps its
/// squircle corners.
class CardHero extends StatelessWidget {
  final schemaless.Credential credential;
  final double width;
  final String? hintText;
  final bool shadow;

  const CardHero({
    super.key,
    required this.credential,
    required this.width,
    this.hintText,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: WalletTransition.heroTag(credential.hash),
      createRectTween: WalletTransition.rectTween,
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
        shadow: shadow,
      ),
    );
  }
}
