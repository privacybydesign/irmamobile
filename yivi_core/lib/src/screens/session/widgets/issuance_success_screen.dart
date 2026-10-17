import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../util/navigation.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/card_pile.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../data/wallet/issuance_flight.dart";

/// "Success" after adding cards: the card with a green check, or the pile
/// of cards with one check for several.
///
/// Inside a request ([backTo] is its requestor), it says that the request
/// comes next and the button goes back to it.
class IssuanceSuccessScreen extends StatefulWidget {
  final Function(BuildContext) onDismiss;

  /// The credentials just added.
  final List<schemaless.Credential> credentials;

  /// On "OK" a card flies into the data tab instead of the screen closing
  /// as usual. Off when the session returns somewhere else.
  final bool flyHome;

  /// The requestor of the request this issuance was for, if any.
  final String? backTo;

  const IssuanceSuccessScreen({
    super.key,
    required this.onDismiss,
    this.credentials = const [],
    this.flyHome = false,
    this.backTo,
  });

  @override
  State<IssuanceSuccessScreen> createState() => _IssuanceSuccessScreenState();
}

class _IssuanceSuccessScreenState extends State<IssuanceSuccessScreen> {
  late final _cardKeys = [
    for (final (i, _) in widget.credentials.indexed)
      GlobalKey(debugLabel: "received_card_$i"),
  ];

  void _done() {
    if (widget.flyHome && _fly()) {
      // The curtain hides the switch, so no pop animation.
      context.goHomeScreenWithoutTransition();
    } else {
      widget.onDismiss(context);
    }
  }

  /// Flies the received card that now leads the data tab, if any.
  bool _fly() => IssuanceFlight.startFirstOf(
    context,
    received: widget.credentials,
    sources: _cardKeys,
  );

  @override
  Widget build(BuildContext context) {
    final cards = widget.credentials;
    final many = cards.length > 1;
    final back = widget.backTo;
    final params = {
      "name": cards.firstOrNull?.name ?? "",
      "count": "${cards.length}",
      "requestor": ?back,
    };
    final text = cards.isEmpty
        ? "issuance.success_feedback.text"
        : "issuance.success_feedback.added_${many ? "many" : "one"}"
              "${back == null ? "" : "_back"}";

    return ActionFeedback(
      success: true,
      titleTranslationKey: "issuance.success_feedback.header",
      explanationTranslationKey: text,
      explanationTranslationParams: params,
      buttonTranslationKey: back == null
          ? "action_feedback.ok"
          : "issuance.success_feedback.back_to",
      buttonTranslationParams: params,
      onDismiss: _done,
      hero: cards.isEmpty
          ? null
          : IssuanceReceived(cards: cards, cardKeys: _cardKeys),
    );
  }
}

/// The received card with a green check, or the pile of cards with one
/// check for several: the hero of the success screen, and of the last page
/// of adding a card in the Change sheet. [cardKeys] (one per card) mark
/// where a card flies from afterwards.
class IssuanceReceived extends StatelessWidget {
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;

  const IssuanceReceived({
    super.key,
    required this.cards,
    required this.cardKeys,
  }) : assert(cards.length == cardKeys.length);

  @override
  Widget build(BuildContext context) => cards.length > 1
      ? _ReceivedPile(cards, cardKeys: cardKeys)
      : _ReceivedCard(cards.first, cardKey: cardKeys.first);
}

/// Settles into place: drops in from above with a slight tilt.
class _Arrive extends StatelessWidget {
  final Widget child;

  const _Arrive({required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -60),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The green check on the received card or pile.
class _CheckBadge extends StatelessWidget {
  final double size;

  const _CheckBadge({this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key("received_check"),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF00973A),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 4,
        ),
      ),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.54),
    );
  }
}

/// The received card, settling into place with a green check badge.
class _ReceivedCard extends StatelessWidget {
  final schemaless.Credential credential;
  final GlobalKey cardKey;

  const _ReceivedCard(this.credential, {required this.cardKey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 48).clamp(0.0, 360.0);
        return Center(
          child: _Arrive(
            child: Transform.rotate(
              angle: -0.035,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CredentialCardArt(
                      key: cardKey,
                      credential: credential,
                      width: width,
                    ),
                    const Positioned(
                      right: -12,
                      top: -16,
                      child: _CheckBadge(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Several received cards as the pile from the permission screen, with one
/// check at its top right.
class _ReceivedPile extends StatelessWidget {
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;

  const _ReceivedPile(this.cards, {required this.cardKeys});

  @override
  Widget build(BuildContext context) {
    const pile = CardPile(cards: []);
    return Center(
      child: _Arrive(
        child: SizedBox(
          width: 320,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CardPile(cards: cards, cardKeys: cardKeys),
              // Over the right edge of the pile's widest card.
              Positioned(
                left: (320 - pile.cardWidth) / 2 + pile.cardWidth + 6,
                top: -14,
                child: const _CheckBadge(size: 52),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
