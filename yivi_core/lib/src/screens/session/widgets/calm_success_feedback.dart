import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "success_graphic.dart";

const _graphicWidth = 230.0;
const _graphicHeight = 239.0;
const _contentVerticalPadding = 56.0;
const _closeButtonSize = 48.0;
const _closeIconSize = 22.0;
const _headingLineHeight = 28.0;

/// The success screen of the calm success flag (J1, J2): a white page with the
/// facts in the heading and a hint below it.
class CalmSuccessFeedback extends StatelessWidget {
  final String appBarTranslationKey;
  final String headingTranslationKey;
  final Map<String, String>? headingTranslationParams;
  final String textTranslationKey;
  final VoidCallback onDismiss;

  const CalmSuccessFeedback({
    super.key,
    required this.appBarTranslationKey,
    required this.headingTranslationKey,
    this.headingTranslationParams,
    required this.textTranslationKey,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final headingStyle = theme.bodyHeading!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.light,
        appBar: IrmaAppBar(
          titleTranslationKey: appBarTranslationKey,
          leading: null,
          hasBorder: false,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: theme.tinySpacing),
              child: IrmaIconButton(
                icon: Icons.close,
                size: _closeIconSize,
                padding: const EdgeInsets.all(
                  (_closeButtonSize - _closeIconSize) / 2,
                ),
                color: theme.dark,
                semanticsLabelKey: "accessibility.close",
                onTap: onDismiss,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: theme.largeSpacing,
            vertical: _contentVerticalPadding,
          ),
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  width: _graphicWidth,
                  height: _graphicHeight,
                  child: SuccessGraphic(),
                ),
                SizedBox(height: theme.mediumSpacing),
                TranslatedText(
                  headingTranslationKey,
                  translationParams: headingTranslationParams,
                  isHeader: true,
                  style: headingStyle.copyWith(
                    height: _headingLineHeight / headingStyle.fontSize!,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: theme.mediumSpacing),
                TranslatedText(
                  textTranslationKey,
                  style: theme.textTheme.bodyMedium!.copyWith(letterSpacing: 0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.light,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                offset: const Offset(0.0, -1.0),
                blurRadius: 6.0,
              ),
            ],
          ),
          // The board's 32 px below the button is the whole bottom edge, so
          // the system inset counts towards it.
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(
              theme.defaultSpacing,
              theme.defaultSpacing,
              theme.defaultSpacing,
              theme.largeSpacing,
            ),
            child: YiviThemedButton(
              key: const Key("ok_button"),
              label: "action_feedback.ok",
              size: YiviButtonSize.compact,
              onPressed: onDismiss,
            ),
          ),
        ),
      ),
    );
  }
}
