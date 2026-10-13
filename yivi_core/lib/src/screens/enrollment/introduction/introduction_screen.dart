import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "../../../../package_name.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../widgets/enrollment_hero.dart";
import "../widgets/enrollment_instruction.dart";
import "../widgets/enrollment_layout.dart";
import "../widgets/enrollment_nav_bar.dart";
import "models/introduction_entry.dart";
import "models/introduction_step.dart";
import "widgets/introduction_animation_wrapper.dart";

const double _heroSize = 300;
const double _pageTopSpacing = 48;
const double _textSpacing = 12;
const String _onboardingV2ExplanationKey =
    "enrollment.onboarding_v2.intro_explanation";

class IntroductionScreen extends ConsumerStatefulWidget {
  static const String routeName = "introduction";

  static List<IntroductionStep> introductionSteps = [
    IntroductionStep(
      imagePath: yiviAsset("enrollment/introduction_1.svg"),
      titleTranslationKey: "enrollment.introduction.step_1.title",
      explanationTranslationKey: "enrollment.introduction.step_1.explanation",
    ),
    IntroductionStep(
      imagePath: yiviAsset("enrollment/introduction_2.json"),
      titleTranslationKey: "enrollment.introduction.step_2.title",
      explanationTranslationKey: "enrollment.introduction.step_2.explanation",
    ),
    IntroductionStep(
      imagePath: yiviAsset("enrollment/introduction_3.svg"),
      titleTranslationKey: "enrollment.introduction.step_3.title",
      explanationTranslationKey: "enrollment.introduction.step_3.explanation",
    ),
  ];

  final int currentStepIndex;
  final IntroductionEntry entry;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const IntroductionScreen({
    super.key,
    required this.currentStepIndex,
    this.entry = IntroductionEntry.first,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  ConsumerState<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends ConsumerState<IntroductionScreen> {
  bool skipAnimation = false;

  @override
  void initState() {
    super.initState();
    // Skip the animation when going back from a screen
    // further in the enrollment flow
    if (widget.currentStepIndex > 0 ||
        widget.entry == IntroductionEntry.returning) {
      skipAnimation = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Onboarding v2 has a single introduction page, so no progress dots.
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;

    Widget contentWidget = EnrollmentLayout(
      hero: EnrollmentHero(
        IntroductionScreen.introductionSteps[widget.currentStepIndex].imagePath,
      ),
      instruction: EnrollmentInstruction(
        stepIndex: onboardingV2 ? null : widget.currentStepIndex,
        stepCount: onboardingV2
            ? null
            : IntroductionScreen.introductionSteps.length,
        titleTranslationKey: IntroductionScreen
            .introductionSteps[widget.currentStepIndex]
            .titleTranslationKey,
        explanationTranslationKey: IntroductionScreen
            .introductionSteps[widget.currentStepIndex]
            .explanationTranslationKey,
        onContinue: widget.onContinue,
        onPrevious: widget.currentStepIndex != 0 ? widget.onPrevious : null,
      ),
    );

    // Onboarding v2 draws one page in portrait. Landscape keeps the hero
    // beside the text, which the design does not cover.
    if (onboardingV2 && !isLandscape) {
      contentWidget = _OnboardingPage(
        step: IntroductionScreen.introductionSteps[widget.currentStepIndex],
        onContinue: widget.onContinue,
      );
    }

    if (!skipAnimation) {
      contentWidget = IntroductionAnimationWrapper(child: contentWidget);
    }

    return Scaffold(
      body: SafeArea(bottom: isLandscape, child: contentWidget),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IntroductionStep step;
  final VoidCallback onContinue;

  const _OnboardingPage({required this.step, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              theme.mediumSpacing,
              _pageTopSpacing,
              theme.mediumSpacing,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox.square(
                      dimension: _heroSize,
                      child: EnrollmentHero(step.imagePath),
                    ),
                  ),
                  SizedBox(height: theme.largeSpacing),
                  TranslatedText(
                    step.titleTranslationKey,
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: _textSpacing),
                  const TranslatedText(_onboardingV2ExplanationKey),
                ],
              ),
            ),
          ),
        ),
        EnrollmentNavBar(onContinue: onContinue),
      ],
    );
  }
}
