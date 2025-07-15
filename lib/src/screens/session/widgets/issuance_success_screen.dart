import 'package:flutter/material.dart';

import '../../../widgets/action_feedback.dart';

class IssuanceSuccessScreen extends StatelessWidget {
  final Function(BuildContext) onDismiss;

  const IssuanceSuccessScreen({
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: true,
      titleTranslationKey: 'issuance.success_feedback.header',
      explanationTranslationKey: 'issuance.success_feedback.text',
      onDismiss: () => onDismiss(context),
    );
  }
}
