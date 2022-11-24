import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../screens/session/widgets/dynamic_layout.dart';
import '../theme/theme.dart';
import 'irma_button.dart';
import 'irma_themed_button.dart';
import 'translated_text.dart';

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
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  onPressed: () => dismiss(context),
                  icon: Icon(
                    Icons.close_outlined,
                    semanticLabel: FlutterI18n.translate(context, 'accessibility.close'),
                    size: 16.0,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: DynamicLayout(
          hero: SvgPicture.asset(
            success
                ? 'assets/disclosure/disclosure_happy_illustration.svg'
                : 'assets/error/general_error_illustration.svg',
          ),
          content: Column(
            children: [
              TranslatedText(
                titleTranslationKey,
                translationParams: titleTranslationParams,
                style: theme.textTheme.headline1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.defaultSpacing),
              TranslatedText(
                explanationTranslationKey,
                translationParams: explanationTranslationParams,
                style: theme.textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            IrmaButton(
              label: 'action_feedback.ok',
              size: IrmaButtonSize.large,
              onPressed: () => dismiss(context),
            )
          ],
        ),
      ),
    );
  }
}
