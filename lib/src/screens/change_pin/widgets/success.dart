import 'package:flutter/material.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/action_feedback.dart';

class Success extends StatelessWidget {
  static const String routeName = 'change_pin/success';

  final void Function() cancel;

  const Success({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: true,
      title: TranslatedText(
        "change_pin.success.title",
        style: Theme.of(context).textTheme.display3,
      ),
      explanation: const TranslatedText(
        "change_pin.success.message",
        textAlign: TextAlign.center,
      ),
      onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }
}
