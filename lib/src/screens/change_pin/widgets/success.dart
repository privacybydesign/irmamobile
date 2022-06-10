import 'package:flutter/material.dart';

import '../../../widgets/action_feedback.dart';

class Success extends StatelessWidget {
  static const String routeName = 'change_pin/success';

  final void Function() cancel;

  const Success({
    required this.cancel,
  });

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: true,
      titleTranslationKey: 'change_pin.success.title',
      explanationTranslationKey: 'change_pin.success.message',
      onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }
}
