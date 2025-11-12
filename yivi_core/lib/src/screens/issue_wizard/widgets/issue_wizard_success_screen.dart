import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/translated_value.dart';
import '../../../widgets/action_feedback.dart';

class IssueWizardSuccessScreenArgs {
  final TranslatedValue? headerTranslation;
  final TranslatedValue? contentTranslation;

  IssueWizardSuccessScreenArgs({required this.headerTranslation, required this.contentTranslation});
}

class IssueWizardSuccessScreen extends StatelessWidget {
  final IssueWizardSuccessScreenArgs args;
  final VoidCallback onDismiss;

  const IssueWizardSuccessScreen({
    required this.args,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return ActionFeedback(
      success: true,
      titleTranslationKey:
          args.headerTranslation != null ? args.headerTranslation!.translate(lang) : 'issue_wizard.success.header',
      explanationTranslationKey:
          args.contentTranslation != null ? args.contentTranslation!.translate(lang) : 'issue_wizard.success.content',
      onDismiss: onDismiss,
    );
  }
}
