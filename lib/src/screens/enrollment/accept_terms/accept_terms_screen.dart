import 'package:flutter/material.dart';

import '../widgets/enrollment_graphic.dart';
import '../widgets/enrollment_layout.dart';
import 'widget/accept_terms_Instruction.dart';

class AcceptTermsScreen extends StatelessWidget {
  static const String routeName = 'terms';

  final bool isAccepted;
  final Function(bool) onToggleAccepted;
  final VoidCallback onContinue;

  const AcceptTermsScreen({
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnrollmentLayout(
        graphic: const EnrollmentGraphic('assets/enrollment/introduction_screen3.svg'),
        instruction: AcceptTermsInstruction(
          titleTranslationKey: 'enrollment.terms_and_conditions.title',
          explanationTranslationKey: 'enrollment.terms_and_conditions.explanation',
          isAccepted: isAccepted,
          onContinue: onContinue,
          onToggleAccepted: onToggleAccepted,
        ),
      ),
    );
  }
}
