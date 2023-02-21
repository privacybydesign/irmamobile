import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../screens/session/widgets/dynamic_layout.dart';
import '../screens/session/widgets/session_scaffold.dart';
import '../theme/theme.dart';
import 'translated_text.dart';
import 'yivi_themed_button.dart';

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;
  final bool success;
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String explanationTranslationKey;
  final Map<String, String>? explanationTranslationParams;

  const ActionFeedback({
    required this.success,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    required this.explanationTranslationKey,
    this.explanationTranslationParams,
    required this.onDismiss,
  });

  void dismiss(BuildContext context) {
    Navigator.of(context).pop();
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return WillPopScope(
      onWillPop: () async {
        dismiss(context);
        return false;
      },
      child: SessionScaffold(
        appBarTitle: success ? 'disclosure.feedback.header.success' : 'ui.error',
        onDismiss: onDismiss,
        body: DynamicLayout(
          hero: SvgPicture.asset(
            success ? 'assets/disclosure/disclosure_success.svg' : 'assets/error/general_error_illustration.svg',
          ),
          content: Column(
            children: [
              TranslatedText(
                titleTranslationKey,
                style: theme.themeData.textTheme.headline3!.copyWith(
                  color: theme.dark,
                ),
              ),
              SizedBox(
                height: theme.tinySpacing,
              ),
              TranslatedText(
                explanationTranslationKey,
                translationParams: explanationTranslationParams,
                style: theme.themeData.textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            YiviThemedButton(
              label: 'action_feedback.ok',
              onPressed: () => dismiss(context),
            ),
          ],
        ),
      ),
    );
  }
}
