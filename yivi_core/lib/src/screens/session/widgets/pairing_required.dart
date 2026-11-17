import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/icon_square.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "requestor_card.dart";
import "requestor_trust_sheet.dart";
import "session_scaffold.dart";

/// The pairing code to type on the website: who asks for it (or a shield
/// when that is not known), what to do, the code in four large boxes, and
/// a spinner while the website has not confirmed it.
class PairingRequired extends StatelessWidget {
  final String pairingCode;
  final TrustedParty? requestor;
  final Function() onDismiss;

  const PairingRequired({
    super.key,
    required this.pairingCode,
    this.requestor,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // A requestor without a name is not known: the shield, not an empty
    // card that says it is unchecked.
    final who = (requestor?.name.trim().isNotEmpty ?? false) ? requestor : null;
    final instruction = who == null
        ? context.tr("session.pairing.instruction")
        : context.tr("session.pairing.explanation", {"requestor": who.name});
    final edge = YiviEdges.block(context);

    return SessionScaffold(
      appBarTitle: "session.pairing.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: context.tr("session.navigation_bar.cancel"),
        onSecondaryPressed: () => onDismiss(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x32,
            YiviSpace.x24,
            YiviSpace.x32,
            YiviSpace.x32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (who != null)
                // Who asks, as on the share screen; ⓘ explains who vouches.
                RequestorCard(
                  requestor: who,
                  onInfo: () => showRequestorTrustSheet(
                    context: context,
                    requestor: who,
                    onDontShare: onDismiss,
                  ),
                )
              else
                ExcludeSemantics(
                  child: IconSquare(
                    icon: Icons.verified_user_rounded,
                    fill: palette.surface,
                    ink: palette.link,
                    size: 96,
                    iconSize: 48,
                    radius: YiviCorners.iconTile,
                    side: edge,
                  ),
                ),
              const SizedBox(height: YiviSpace.x24),
              if (who != null) ...[
                Semantics(
                  header: true,
                  child: Text(
                    context.tr("session.pairing.heading"),
                    key: const Key("pairing_heading"),
                    textAlign: TextAlign.center,
                    style: palette.titleStep.copyWith(color: palette.text),
                  ),
                ),
                const SizedBox(height: YiviSpace.x12),
              ],
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: palette
                    .body(who == null ? 16 : 15)
                    .copyWith(
                      height: who == null ? 24 / 16 : 22 / 15,
                      color: who == null ? null : palette.heading,
                    ),
              ),
              const SizedBox(height: YiviSpace.x32),
              // Read out as one code, character by character.
              Semantics(
                label: pairingCode.split("").join(" "),
                excludeSemantics: true,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (i, char) in pairingCode.split("").indexed)
                      Container(
                        key: Key("pairing_code_box_$i"),
                        width: 60,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: palette.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: YiviCorners.cardRadius,
                            side: edge,
                          ),
                        ),
                        child: Text(
                          char,
                          style: palette
                              .display(34, weight: FontWeight.w700)
                              .copyWith(color: palette.heading),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: YiviSpace.x32),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: YiviSpace.x12,
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: palette.heading,
                      backgroundColor: palette.outline,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      context.tr("session.pairing.waiting"),
                      style: palette
                          .body(14)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
