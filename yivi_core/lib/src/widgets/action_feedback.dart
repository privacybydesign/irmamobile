import "package:material_ui/material_ui.dart";

import "../screens/session/widgets/dynamic_layout.dart";
import "../screens/session/widgets/session_scaffold.dart";
import "../screens/session/widgets/success_graphic.dart";
import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "glass/glass_dialog.dart";
import "translated_text.dart";
import "yivi_themed_button.dart";

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;
  final bool success;
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String explanationTranslationKey;
  final Map<String, String>? explanationTranslationParams;

  /// Replaces the success illustration, e.g. with the card just received.
  final Widget? hero;

  const ActionFeedback({
    this.hero,
    super.key,
    required this.success,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    required this.explanationTranslationKey,
    this.explanationTranslationParams,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return PopScope(
      canPop: false,
      child: SessionScaffold(
        appBarTitle: success
            ? "disclosure.feedback.header.success"
            : "ui.error",
        onDismiss: onDismiss,
        body: DynamicLayout(
          hero: success
              ? (hero ?? SuccessGraphic())
              // A blue disc with a question mark, as the other status
              // screens.
              : const ToneDisc(
                  icon: Icons.help_outline_rounded,
                  tone: DialogTone.info,
                  size: 140,
                ),
          content: Column(
            children: [
              TranslatedText(
                titleTranslationKey,
                style: YiviPalette.of(
                  context,
                ).display(26, weight: FontWeight.w700),
              ),
              SizedBox(height: theme.tinySpacing),
              TranslatedText(
                explanationTranslationKey,
                translationParams: explanationTranslationParams,
                style: YiviPalette.of(context).body(16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            YiviThemedButton(
              key: const Key("ok_button"),
              label: "action_feedback.ok",
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
