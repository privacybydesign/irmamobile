import 'package:flutter/material.dart';

import '../../change_pin/widgets/choose_pin.dart';
import 'models/introduction_step.dart';
import 'widgets/introduction_graphic.dart';
import 'widgets/introduction_instruction.dart';

class Introduction extends StatefulWidget {
  static const String routeName = 'introduction';

  const Introduction();

  @override
  State<Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
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

  Widget _buildGraphic() => IntroductionGraphic(
        _introductionSteps[currentStepIndex].svgImagePath,
      );

  Widget _buildInstruction() => IntroductionInstruction(
        stepIndex: currentStepIndex,
        stepCount: _introductionSteps.length,
        titleTranslationKey: _introductionSteps[currentStepIndex].titleTranslationKey,
        explanationTranslationKey: _introductionSteps[currentStepIndex].explanationTranslationKey,
        onContinue: _onContinue,
        onPrevious: _onPrevious,
      );

  Row _buildLandscapeLayout() => Row(
        children: [
          Flexible(
            flex: 4,
            child: _buildGraphic(),
          ),
          Flexible(
            flex: 5,
            child: _buildInstruction(),
          )
        ],
      );

  Column _buildPortraitLayout() => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            flex: 5,
            child: _buildGraphic(),
          ),
          Flexible(
            flex: 4,
            child: _buildInstruction(),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.height < 450;

    return Scaffold(
      body: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }
}
