import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../package_name.dart";
import "../screens/session/widgets/dynamic_layout.dart";
import "../screens/session/widgets/session_scaffold.dart";
import "../screens/session/widgets/success_graphic.dart";
import "../theme/theme.dart";
import "translated_text.dart";
import "yivi_themed_button.dart";

/// The size of the feedback title.
///
/// [prominent] is for an outcome whose headline IS the message and needs to
/// land before the explanation is read -- the zero-knowledge disclosure, where
/// what matters is not that it worked but how. [normal] everywhere else, so
/// the ordinary success and error screens keep the size they have always had.
enum FeedbackTitleStyle { normal, prominent }

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;
  final bool success;
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String explanationTranslationKey;
  final Map<String, String>? explanationTranslationParams;

  /// Which display size the title is rendered in; see [FeedbackTitleStyle].
  final FeedbackTitleStyle titleStyle;

  const ActionFeedback({
    super.key,
    required this.success,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    required this.explanationTranslationKey,
    this.explanationTranslationParams,
    required this.onDismiss,
    this.titleStyle = FeedbackTitleStyle.normal,
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
              ? SuccessGraphic()
              : SvgPicture.asset(
                  yiviAsset("error/general_error_illustration.svg"),
                ),
          content: Column(
            children: [
              TranslatedText(
                titleTranslationKey,
                style:
                    (titleStyle == FeedbackTitleStyle.prominent
                            ? theme.themeData.textTheme.displayMedium!
                            : theme.themeData.textTheme.displaySmall!)
                        .copyWith(color: theme.dark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.tinySpacing),
              TranslatedText(
                explanationTranslationKey,
                translationParams: explanationTranslationParams,
                style: theme.themeData.textTheme.bodyMedium,
                textAlign: TextAlign.center,
                // textAlign above governs the plain-text path only; a markdown
                // explanation takes its alignment from this instead, and would
                // otherwise sit left-aligned under a centred title.
                markdownTextAlign: WrapAlignment.center,
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
