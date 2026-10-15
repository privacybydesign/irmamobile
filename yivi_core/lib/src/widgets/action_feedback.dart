import "package:material_ui/material_ui.dart";

import "../screens/session/widgets/dynamic_layout.dart";
import "../screens/session/widgets/session_columns.dart";
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

  /// The button's label, "OK" unless set.
  final String buttonTranslationKey;
  final Map<String, String>? buttonTranslationParams;

  const ActionFeedback({
    this.hero,
    super.key,
    required this.success,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    required this.explanationTranslationKey,
    this.explanationTranslationParams,
    required this.onDismiss,
    this.buttonTranslationKey = "action_feedback.ok",
    this.buttonTranslationParams,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final palette = YiviPalette.of(context);

    final graphic = success
        ? (hero ?? SuccessGraphic())
        // A blue disc with a question mark, as the other status screens.
        : const ToneDisc(
            icon: Icons.help_outline_rounded,
            tone: DialogTone.info,
            size: 140,
          );
    final title = TranslatedText(
      titleTranslationKey,
      translationParams: titleTranslationParams,
      style: palette.display(26, weight: FontWeight.w700),
    );
    final explanation = TranslatedText(
      explanationTranslationKey,
      translationParams: explanationTranslationParams,
      style: palette.body(16),
      textAlign: TextAlign.center,
    );
    final button = YiviThemedButton(
      key: const Key("ok_button"),
      label: buttonTranslationKey,
      labelParams: buttonTranslationParams,
      onPressed: onDismiss,
    );

    return PopScope(
      canPop: false,
      child: SessionScaffold(
        appBarTitle: success
            ? "disclosure.feedback.header.success"
            : "ui.error",
        onDismiss: onDismiss,
        // Tablets: one centred column, the button right under the text.
        body: useSessionColumns(context)
            ? SessionCentred(
                children: [
                  hero ?? SizedBox(height: 160, child: graphic),
                  const SizedBox(height: 32),
                  title,
                  SizedBox(height: theme.tinySpacing),
                  explanation,
                  const SizedBox(height: 32),
                  SizedBox(width: 360, child: button),
                ],
              )
            : DynamicLayout(
                hero: graphic,
                content: Column(
                  children: [
                    title,
                    SizedBox(height: theme.tinySpacing),
                    explanation,
                  ],
                ),
                actions: [button],
              ),
      ),
    );
  }
}
