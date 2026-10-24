import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "requestor_trust_sheet.dart";
import "session_requestor_header.dart";
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
    final who = requestor;
    final instruction = who == null
        ? FlutterI18n.translate(context, "session.pairing.instruction")
        : FlutterI18n.translate(
            context,
            "session.pairing.explanation",
            translationParams: {"requestor": who.name},
          );
    final shadow = BoxShadow(
      color: palette.glassShadow,
      blurRadius: 6,
      offset: const Offset(0, 1),
    );

    return SessionScaffold(
      appBarTitle: "session.pairing.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "session.navigation_bar.cancel",
        ),
        onSecondaryPressed: () => onDismiss(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
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
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: ShapeDecoration(
                      color: palette.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(YiviCorners.iconTile),
                        ),
                      ),
                      shadows: [shadow],
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 48,
                      color: palette.link,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (who != null) ...[
                Semantics(
                  header: true,
                  child: Text(
                    FlutterI18n.translate(context, "session.pairing.heading"),
                    key: const Key("pairing_heading"),
                    textAlign: TextAlign.center,
                    style: palette.display(23).copyWith(color: palette.text),
                  ),
                ),
                const SizedBox(height: 12),
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
              const SizedBox(height: 32),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: YiviCorners.cardRadius,
                          ),
                          shadows: [shadow],
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
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
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
                      FlutterI18n.translate(context, "session.pairing.waiting"),
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
