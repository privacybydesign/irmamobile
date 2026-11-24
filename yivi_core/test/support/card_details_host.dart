import "dart:math";

import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/card_transition/card_origin.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition_layer.dart";
import "package:yivi_core/src/screens/data/card_transition/choreography.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/widgets/bars/app_bar.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

/// A card's details opened as the app opens them: in a card transition,
/// over [below], from a list row's thumbnail low on the screen.
class CardDetailsHost {
  final _transitions = GlobalKey<CardTransitionsState>();

  /// The screen with the open-card layer over [below].
  Widget build({Widget below = const SizedBox.expand()}) => CardTransitions(
    key: _transitions,
    child: Stack(
      children: [
        Positioned.fill(child: below),
        const Positioned.fill(child: OpenCardLayer()),
      ],
    ),
  );

  /// The transition running, if one is.
  CardTransition? get current => _transitions.currentState?.current.value;

  /// Opens the details of [hash] (on [found]), or [details] instead.
  void open(
    String hash, {
    String? found,
    Widget Function(BuildContext context, CardTransition transition)? details,
  }) {
    final state = _transitions.currentState!;
    final media = MediaQuery.of(state.context);
    final width = min(
      media.size.width - 32,
      OpenCardLayer.detailsMaxWidth,
    ).toDouble();
    state.open(
      snapshot: TransitionSnapshot(
        origin: CardOrigin.listRow,
        hash: hash,
        picked: 0,
        cards: [Rect.fromLTWH(24, media.size.height - 200, 88, 55.5)],
        target: Rect.fromLTWH(
          (media.size.width - width) / 2,
          media.padding.top + YiviAppBar.contentTop,
          width,
          width / CredentialCardArt.aspectRatio,
        ),
        screenHeight: media.size.height,
      ),
      details:
          details ??
          (context, transition) => CredentialDetailScreen(
            hash: hash,
            found: found,
            transition: transition,
          ),
    );
  }
}
