import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/action_feedback.dart';

enum DisclosureFeedbackType {
  success,
  canceled,
  notSatisfiable,
}

class DisclosureFeedbackScreen extends StatelessWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "notSatisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) popToWallet;

  final String _translationKey;

  DisclosureFeedbackScreen({this.feedbackType, this.otherParty, this.popToWallet})
      : _translationKey = _translationKeys[feedbackType];

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: feedbackType == DisclosureFeedbackType.success,
      title: TranslatedText(
        "disclosure.feedback.header.$_translationKey",
        translationParams: {"otherParty": otherParty},
        style: Theme.of(context).textTheme.display3,
      ),
      explanation: TranslatedText(
        "disclosure.feedback.text.$_translationKey",
        translationParams: {"otherParty": otherParty},
        textAlign: TextAlign.center,
      ),
      onDismiss: () => popToWallet(context),
    );
  }
}
