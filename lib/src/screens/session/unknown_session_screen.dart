import 'package:flutter/material.dart';

import '../../screens/session/session.dart';
import '../../util/navigation.dart';
import '../../widgets/action_feedback.dart';

class UnknownSessionScreen extends StatelessWidget {
  static const String routeName = '/session/unknown';

  final SessionScreenArguments arguments;

  const UnknownSessionScreen({required this.arguments}) : super();

  @override
  Widget build(BuildContext context) => ActionFeedback(
        success: false,
        titleTranslationKey: 'session.unknown_session_type.title',
        explanationTranslationKey: 'session.unknown_session_type.explanation',
        onDismiss: () => (arguments.wizardActive ? popToWizard : popToHome)(context),
      );
}
