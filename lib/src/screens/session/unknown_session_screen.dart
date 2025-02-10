import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/session/session.dart';
import '../../util/navigation.dart';
import '../../widgets/action_feedback.dart';

_popToHome(BuildContext context) {
  context.go('/home');
}

class UnknownSessionScreen extends StatelessWidget {
  static const String routeName = '/session/unknown';

  final SessionScreenArguments arguments;

  const UnknownSessionScreen({required this.arguments}) : super();

  @override
  Widget build(BuildContext context) {
    return ActionFeedback(
      success: false,
      titleTranslationKey: 'session.unknown_session_type.title',
      explanationTranslationKey: 'session.unknown_session_type.explanation',
      onDismiss: () => (arguments.wizardActive ? popToWizard : _popToHome)(context),
    );
  }
}
