import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/status_body.dart";

/// Tells IRMA users once that the app is now called Yivi: the new logo on a
/// white disc, and that their PIN still works.
class NameChangedScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NameChangedScreen({super.key, required this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(
        titleTranslationKey: "name_changed.title",
        leading: null,
      ),
      body: StatusBody(
        // White in both themes: the logo is drawn for a light background.
        discColor: Colors.white,
        picture: Padding(
          padding: const EdgeInsets.all(28),
          child: Image.asset(
            yiviAsset("non-free/logo.png"),
            semanticLabel: "Yivi",
          ),
        ),
        title: FlutterI18n.translate(context, "name_changed.header"),
        message: FlutterI18n.translate(context, "name_changed.explanation"),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "action_feedback.ok",
        onPrimaryPressed: onContinuePressed,
      ),
    );
  }
}
