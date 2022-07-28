import 'package:flutter/material.dart';

import '../widgets/choose_pin.dart';
import '../widgets/enrollment_layout.dart';
import 'models/introduction_step.dart';
import 'widgets/introduction_graphic.dart';
import 'widgets/introduction_instruction.dart';

class IntroductionScreen extends StatefulWidget {
  static const String routeName = 'introduction';

  const IntroductionScreen();

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  var currentStepIndex = 0;

  final List<IntroductionStep> _introductionSteps = const [
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_screen1.svg',
      titleTranslationKey: 'enrollment.introduction.step_1.title',
      explanationTranslationKey: 'enrollment.introduction.step_1.explanation',
    ),
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_screen2.svg',
      titleTranslationKey: 'enrollment.introduction.step_2.title',
      explanationTranslationKey: 'enrollment.introduction.step_2.explanation',
    ),
    IntroductionStep(
      svgImagePath: 'assets/enrollment/introduction_screen3.svg',
      titleTranslationKey: 'enrollment.introduction.step_3.title',
      explanationTranslationKey: 'enrollment.introduction.step_3.explanation',
    )
  ];

  void _onPrevious() {
    if (currentStepIndex != 0) setState(() => currentStepIndex--);
  }

  void _onContinue() {
    if (currentStepIndex == _introductionSteps.length - 1) {
      Navigator.of(context).pushNamed(ChoosePin.routeName);
    } else {
      setState(() => currentStepIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnrollmentLayout(
        graphic: IntroductionGraphic(
          _introductionSteps[currentStepIndex].svgImagePath,
        ),
        instruction: IntroductionInstruction(
          stepIndex: currentStepIndex,
          stepCount: _introductionSteps.length,
          titleTranslationKey: _introductionSteps[currentStepIndex].titleTranslationKey,
          explanationTranslationKey: _introductionSteps[currentStepIndex].explanationTranslationKey,
          onContinue: _onContinue,
          onPrevious: _onPrevious,
        ),
      ),
    );
  }
}
