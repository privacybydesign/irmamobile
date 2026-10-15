import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "credential_card/card_art/credential_card_art.dart";

/// Several cards as a small, loose pile: each one slightly tilted and
/// nudged left or right, tucked under the one before. Used when an issuer
/// offers more than one card, so it is clear at a glance that these are
/// separate cards, while the values below stay the focus.
///
/// The tilt and offset depend only on a card's place in the pile, so the
/// pile looks the same every time (and in golden tests).
class CardPile extends StatelessWidget {
  final List<Credential> cards;
  final double cardWidth;

  /// A key for the card at the same index, e.g. so it can fly elsewhere.
  final List<Key?> cardKeys;

  const CardPile({
    super.key,
    required this.cards,
    this.cardWidth = 200,
    this.cardKeys = const [],
  });

  /// How far each card sits below the one before.
  static const double step = 26;

  /// Room above and below for the tilted corners.
  static const double margin = 12;

  static const _offsets = [-30.0, 26.0, -14.0, 32.0, -22.0, 18.0];
  static const _degrees = [-3.0, 2.5, -1.5, 3.0, -2.0, 1.5];

  /// The sideways nudge (in points) and tilt (in degrees) of card [index].
  static ({double dx, double degrees}) placementOf(int index) => (
    dx: _offsets[index % _offsets.length],
    degrees: _degrees[index % _degrees.length],
  );

  double get cardHeight =>
      cardWidth *
      CredentialCardArt.designHeight /
      CredentialCardArt.designWidth;

  /// The height of a pile of [count] cards.
  double heightFor(int count) =>
      cardHeight + (count - 1).clamp(0, 1 << 20) * step + 2 * margin;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        key: const Key("card_pile"),
        height: heightFor(cards.length),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centre = (constraints.maxWidth - cardWidth) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (i, card) in cards.indexed)
                  Positioned(
                    left: centre + placementOf(i).dx,
                    top: margin + i * step,
                    child: Transform.rotate(
                      angle: placementOf(i).degrees * 3.141592653589793 / 180,
                      child: CredentialCardArt(
                        key: i < cardKeys.length ? cardKeys[i] : null,
                        credential: card,
                        width: cardWidth,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
