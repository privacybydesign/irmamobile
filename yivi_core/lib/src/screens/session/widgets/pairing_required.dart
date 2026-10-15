import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "session_scaffold.dart";

/// The pairing code to type on the website: a shield on a tile, the
/// instruction, the code in four large boxes, and a spinner while the
/// website has not confirmed it.
class PairingRequired extends StatelessWidget {
  final String pairingCode;
  final Function() onDismiss;

  const PairingRequired({required this.pairingCode, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final instruction = FlutterI18n.translate(
      context,
      "session.pairing.instruction",
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
              ExcludeSemantics(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: ShapeDecoration(
                    color: palette.surface,
                    shape: const RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
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
              const SizedBox(height: 32),
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: palette.body(16).copyWith(height: 24 / 16),
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
                          shape: const RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
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
