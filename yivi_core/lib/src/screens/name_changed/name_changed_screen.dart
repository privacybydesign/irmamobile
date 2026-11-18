import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/irma_app_bar.dart";
import "../../widgets/feedback/status_screen.dart";

/// Tells IRMA users once that the app is now called Yivi: the new logo on a
/// white disc, and that their PIN still works.
class NameChangedScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NameChangedScreen({super.key, required this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      appBar: IrmaAppBar(
        titleTranslationKey: "name_changed.title",
        leading: null,
      ),
      // White in both themes: the logo is drawn for a light background.
      discColor: Colors.white,
      picture: Padding(
        padding: const EdgeInsets.all(28),
        child: Image.asset(
          yiviAsset("non-free/logo.png"),
          semanticLabel: "Yivi",
        ),
      ),
      title: context.tr("name_changed.header"),
      message: context.tr("name_changed.explanation"),
      actions: ActionBar.single(
        label: context.tr("action_feedback.ok"),
        onTap: onContinuePressed,
      ),
    );
  }
}
