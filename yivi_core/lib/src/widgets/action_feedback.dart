import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../screens/session/widgets/dynamic_layout.dart";
import "../screens/session/widgets/session_columns.dart";
import "../screens/session/widgets/session_scaffold.dart";
import "../screens/session/widgets/success_graphic.dart";
import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "../util/adaptive_layout.dart";
import "glass/glass_dialog.dart";
import "glass/pill_buttons.dart";
import "irma_app_bar.dart";
import "landscape_action_bar.dart";
import "translated_text.dart";

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
    final button = FancyPillButton(
      key: const Key("ok_button"),
      label: FlutterI18n.translate(
        context,
        buttonTranslationKey,
        translationParams: buttonTranslationParams,
      ),
      onPressed: onDismiss,
    );

    // A phone held sideways: the picture (the card with its check) at the
    // left, the words at the right, the button at the bottom right, as on
    // "Shared".
    if (!useSessionColumns(context) && useSheetColumns(context)) {
      return PopScope(
        canPop: false,
        child: SessionScaffold(
          appBarTitle: success
              ? "disclosure.feedback.header.success"
              : "ui.error",
          onDismiss: onDismiss,
          wide: true,
          scrollsUnderBars: true,
          cornerClose: true,
          bottomNavigationBar: LandscapeActionBar(child: button),
          body: Builder(
            builder: (context) {
              final insets = MediaQuery.paddingOf(context);
              final top = cornerContentTop(context);
              return Padding(
                key: const Key("action_feedback_landscape"),
                padding: EdgeInsets.fromLTRB(
                  16 + insets.left,
                  top,
                  16 + insets.right,
                  insets.bottom,
                ),
                child: Row(
                  spacing: 32,
                  children: [
                    Expanded(
                      child: Center(
                        child: hero ?? SizedBox(height: 140, child: graphic),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            SizedBox(height: theme.tinySpacing),
                            TranslatedText(
                              explanationTranslationKey,
                              translationParams: explanationTranslationParams,
                              style: palette.body(16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

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
