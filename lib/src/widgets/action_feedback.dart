import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../screens/session/widgets/dynamic_layout.dart';
import '../screens/session/widgets/session_scaffold.dart';
import '../screens/session/widgets/success_graphic.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return PopScope(
      canPop: false,
      child: SessionScaffold(
        appBarTitle: success ? 'disclosure.feedback.header.success' : 'ui.error',
        onDismiss: onDismiss,
        body: DynamicLayout(
          hero: success
              ? SuccessGraphic()
              : SvgPicture.asset(
                  'assets/error/general_error_illustration.svg',
                ),
          content: Column(
            children: [
              TranslatedText(
                titleTranslationKey,
                style: theme.themeData.textTheme.displaySmall!.copyWith(
                  color: theme.dark,
                ),
              ),
              SizedBox(
                height: theme.tinySpacing,
              ),
              TranslatedText(
                explanationTranslationKey,
                translationParams: explanationTranslationParams,
                style: theme.themeData.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            YiviThemedButton(
              label: 'action_feedback.ok',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
