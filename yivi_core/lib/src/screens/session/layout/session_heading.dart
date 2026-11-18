import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../requestor/requestor_card.dart";

/// The top of a session page that asks something: the question as the
/// page's heading, and under it the party it is about as a card
/// ([RequestorCard.compact]: its logo and badge, its name, who vouches for
/// it, and an ⓘ, [onInfo]). Who asks on the share screen; who gives the
/// card on the question whether to add it.
class SessionHeading extends StatelessWidget {
  final String title;
  final TrustedParty party;
  final VoidCallback onInfo;

  /// The heading's key: the bar's title once it has scrolled under the bar.
  final Key? titleKey;

  /// Where the party's logo is: it flies into the party's page.
  final GlobalKey? logoKey;

  /// The party's card, to see when it goes under the bar.
  final GlobalKey? cardKey;

  /// The logo is a hero into the trust sheet ([RequestorLogo.heroTag]).
  final Object? logoHeroTag;

  /// Between the heading and the card.
  final double gap;

  const SessionHeading({
    super.key,
    required this.title,
    required this.party,
    required this.onInfo,
    this.titleKey,
    this.logoKey,
    this.cardKey,
    this.logoHeroTag,
    this.gap = YiviSpace.x16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x4),
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: titleKey,
              style: palette.titleStep.copyWith(color: palette.text),
            ),
          ),
        ),
        SizedBox(height: gap),
        KeyedSubtree(
          key: cardKey,
          child: RequestorCard.compact(
            requestor: party,
            onInfo: onInfo,
            logoKey: logoKey,
            logoHeroTag: logoHeroTag,
          ),
        ),
      ],
    );
  }
}
