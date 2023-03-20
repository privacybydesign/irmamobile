import 'package:flutter/material.dart';

import '../widgets/enrollment_graphic.dart';
import '../widgets/enrollment_instruction.dart';
import '../widgets/enrollment_layout.dart';
import 'models/introduction_step.dart';
import 'widgets/introduction_animation_wrapper.dart';

class IntroductionScreen extends StatefulWidget {
  static const String routeName = 'introduction';

  static List<IntroductionStep> introductionSteps = List.generate(
    3,
    (int stepIndex) {
      final step = stepIndex + 1;
      return IntroductionStep(
        imagePath: 'assets/enrollment/introduction_$step.svg',
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
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  bool skipAnimation = false;

  @override
  void initState() {
    super.initState();
    // Skip the animation when going back from a screen
    // further in the enrollment flow
    if (widget.currentStepIndex > 0) {
      skipAnimation = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    Widget contentWidget = EnrollmentLayout(
      graphic: EnrollmentGraphic(
        IntroductionScreen.introductionSteps[widget.currentStepIndex].imagePath,
      ),
      instruction: EnrollmentInstruction(
        stepIndex: widget.currentStepIndex,
        stepCount: IntroductionScreen.introductionSteps.length,
        titleTranslationKey: IntroductionScreen.introductionSteps[widget.currentStepIndex].titleTranslationKey,
        explanationTranslationKey:
            IntroductionScreen.introductionSteps[widget.currentStepIndex].explanationTranslationKey,
        onContinue: widget.onContinue,
        onPrevious: widget.currentStepIndex != 0 ? widget.onPrevious : null,
      ),
    );

    if (!skipAnimation) {
      contentWidget = IntroductionAnimationWrapper(
        child: contentWidget,
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: isLandscape,
        child: contentWidget,
      ),
    );
  }
}
