import 'package:flutter/material.dart';

import '../widgets/enrollment_graphic.dart';
import '../widgets/enrollment_instruction.dart';
import '../widgets/enrollment_layout.dart';
import 'models/introduction_step.dart';

class IntroductionScreen extends StatelessWidget {
  static const String routeName = 'introduction';

  static const List<IntroductionStep> introductionSteps = [
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_1.svg',
      titleTranslationKey: 'enrollment.introduction.step_1.title',
      explanationTranslationKey: 'enrollment.introduction.step_1.explanation',
    ),
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_2.svg',
      titleTranslationKey: 'enrollment.introduction.step_2.title',
      explanationTranslationKey: 'enrollment.introduction.step_2.explanation',
    ),
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_3.svg',
      titleTranslationKey: 'enrollment.introduction.step_3.title',
      explanationTranslationKey: 'enrollment.introduction.step_3.explanation',
    )
  ];

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
          onPrevious: onPrevious,
        ),
      ),
    );
  }
}
