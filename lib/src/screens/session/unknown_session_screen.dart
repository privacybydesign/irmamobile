import 'package:flutter/material.dart';

import '../../screens/session/session.dart';
import '../../util/navigation.dart';
import '../../widgets/action_feedback.dart';

class UnknownSessionScreen extends StatefulWidget {
  static const String routeName = '/session/unknown';

  final SessionScreenArguments arguments;

  const UnknownSessionScreen({required this.arguments}) : super();

  @override
  State<UnknownSessionScreen> createState() => _UnknownSessionScreenState();
}

class _UnknownSessionScreenState extends State<UnknownSessionScreen> {
  @override
  Widget build(BuildContext context) => ActionFeedback(
        success: false,
        titleTranslationKey: 'session.unknown_session_type.title',
        explanationTranslationKey: 'session.unknown_session_type.explanation',
        onDismiss: () => (widget.arguments.wizardActive ? popToWizard : popToHome)(context),
      );
}
