import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/translated_value.dart';
import '../../../widgets/action_feedback.dart';

class IssueWizardSuccessScreen extends StatelessWidget {
  final TranslatedValue? headerTranslation;
  final TranslatedValue? contentTranslation;
  final VoidCallback onDismiss;

  const IssueWizardSuccessScreen({
    this.headerTranslation,
    this.contentTranslation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return ActionFeedback(
      success: true,
      titleTranslationKey:
          headerTranslation != null ? headerTranslation!.translate(lang) : 'issue_wizard.success.header',
      explanationTranslationKey:
          contentTranslation != null ? contentTranslation!.translate(lang) : 'issue_wizard.success.content',
      onDismiss: onDismiss,
    );
  }
}
