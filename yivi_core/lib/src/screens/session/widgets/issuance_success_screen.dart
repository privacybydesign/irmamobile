import "dart:math" as math;

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/navigation.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/card_pile.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../data/wallet/issuance_flight.dart";
import "issuance_permission.dart";
import "session_columns.dart";
import "session_scaffold.dart";

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

    // Held sideways, as the share screen and the permission: the card and
    // the button in a panel at the left, the words and what is now in the
    // app at the right.
    if (cards.isNotEmpty &&
        !useSessionColumns(context) &&
        useSheetColumns(context)) {
      String t(String key) =>
          FlutterI18n.translate(context, key, translationParams: params);
      final palette = YiviPalette.of(context);
      return PopScope(
        canPop: false,
        child: SessionScaffold(
          appBarTitle: "issuance.success_feedback.header",
          onDismiss: _done,
          wide: true,
          scrollsUnderBars: true,
          cornerClose: true,
          body: IssuanceLandscape(
            key: const Key("issuance_success_landscape"),
            title: t("issuance.success_feedback.header"),
            note: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                t(text),
                style: palette.body(16).copyWith(height: 24 / 16),
              ),
            ),
            overview: [
              Padding(
                // Room for the check over the card's corner.
                padding: const EdgeInsets.only(top: 14),
                child: IssuanceReceived(cards: cards, cardKeys: _cardKeys),
              ),
            ],
            receives: IssuanceOffer(
              cards: cards,
              showRequestChip: false,
            ).receives(context, headingKey: "data.add.in_your_app"),
            actions: FancyPillButton(
              key: const Key("ok_button"),
              label: t(
                back == null
                    ? "action_feedback.ok"
                    : "issuance.success_feedback.back_to",
              ),
              size: PillSize.regular,
              onPressed: _done,
            ),
          ),
        ),
      );
    }

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
/// check on the front card's corner, where the single card has it.
class _ReceivedPile extends StatelessWidget {
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;

  const _ReceivedPile(this.cards, {required this.cardKeys});

  /// The width the pile is drawn for, its cards 200 wide.
  static const double _designWidth = 320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Smaller where there is less room (the panel of a phone held
        // sideways), so the pile and its check stay inside it.
        final width = math.min(_designWidth, constraints.maxWidth);
        final pile = CardPile(
          cards: cards,
          cardKeys: cardKeys,
          cardWidth: 200 * width / _designWidth,
        );
        final front = cards.length - 1;
        final frontLeft =
            (width - pile.cardWidth) / 2 + CardPile.placementOf(front).dx;
        const check = 52.0;
        return Center(
          child: _Arrive(
            child: SizedBox(
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  pile,
                  Positioned(
                    left: frontLeft + pile.cardWidth + 12 - check,
                    top: CardPile.margin + front * CardPile.step - 16,
                    child: const _CheckBadge(size: check),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
