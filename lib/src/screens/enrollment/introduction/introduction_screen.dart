import 'package:flutter/material.dart';

import '../widgets/enrollment_graphic.dart';
import '../widgets/enrollment_instruction.dart';
import '../widgets/enrollment_layout.dart';
import 'models/introduction_step.dart';

class IntroductionScreen extends StatelessWidget {
  static const String routeName = 'introduction';

  static List<IntroductionStep> introductionSteps = List.generate(
    3,
    (int stepIndex) {
      final step = stepIndex + 1;
      return IntroductionStep(
        svgImagePath: 'assets/enrollment/introduction_$step.svg',
        titleTranslationKey: 'enrollment.introduction.step_$step.title',
        explanationTranslationKey: 'enrollment.introduction.step_$step.explanation',
      );
    },
    growable: false,
  );

  final int currentStepIndex;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const IntroductionScreen({
    required this.currentStepIndex,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnrollmentLayout(
        graphic: EnrollmentGraphic(
          introductionSteps[currentStepIndex].svgImagePath,
        ),
        instruction: EnrollmentInstruction(
          stepIndex: currentStepIndex,
          stepCount: introductionSteps.length,
          titleTranslationKey: introductionSteps[currentStepIndex].titleTranslationKey,
          explanationTranslationKey: introductionSteps[currentStepIndex].explanationTranslationKey,
          onContinue: onContinue,
          onPrevious: currentStepIndex != 0 ? onPrevious : null,
        ),
      ),
    );
  }
}
