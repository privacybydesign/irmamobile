import "package:material_ui/material_ui.dart";

import "../../../widgets/action_feedback.dart";

class EmailLinkedScreen extends StatelessWidget {
  final Function(BuildContext) onDismiss;

  const EmailLinkedScreen({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: true,
      titleTranslationKey: "email_linking.done.title",
      explanationTranslationKey: "email_linking.done.body",
      onDismiss: () => onDismiss(context),
    );
  }
}
