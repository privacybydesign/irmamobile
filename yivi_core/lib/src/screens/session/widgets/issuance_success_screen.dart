import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../util/navigation.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../data/wallet/issuance_flight.dart";

class IssuanceSuccessScreen extends StatefulWidget {
  final Function(BuildContext) onDismiss;

  /// The credentials just added; the first is shown with a check badge.
  final List<schemaless.Credential> credentials;

  /// On "Done" the card flies into the data tab instead of the screen
  /// closing as usual. Off when the session returns somewhere else.
  final bool flyHome;

  const IssuanceSuccessScreen({
    required this.onDismiss,
    this.credentials = const [],
    this.flyHome = false,
  });

  @override
  State<IssuanceSuccessScreen> createState() => _IssuanceSuccessScreenState();
}

class _IssuanceSuccessScreenState extends State<IssuanceSuccessScreen> {
  final _cardKey = GlobalKey(debugLabel: "received_card");

  void _done() {
    final flying =
        widget.flyHome &&
        widget.credentials.isNotEmpty &&
        IssuanceFlight.start(
          context,
          received: widget.credentials.first,
          source: _cardKey,
        );
    if (flying) {
      // The curtain hides the switch, so no pop animation.
      context.goHomeScreenWithoutTransition();
    } else {
      widget.onDismiss(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: true,
      titleTranslationKey: "issuance.success_feedback.header",
      explanationTranslationKey: "issuance.success_feedback.text",
      onDismiss: _done,
      hero: widget.credentials.isEmpty
          ? null
          : _ReceivedCard(widget.credentials.first, cardKey: _cardKey),
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 48).clamp(0.0, 360.0);
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -60),
                child: Transform.rotate(angle: -0.035 * t, child: child),
              ),
            ),
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
                  Positioned(
                    right: -12,
                    top: -16,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00973A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
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
