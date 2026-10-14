import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "../../../../package_name.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../widgets/enrollment_instruction.dart";
import "../widgets/enrollment_layout.dart";
import "models/introduction_entry.dart";
import "models/introduction_step.dart";
import "widgets/introduction_animation_wrapper.dart";
import "widgets/introduction_art.dart";

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
    // Onboarding v2 has a single introduction page, so no progress dots.
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;
    final step = IntroductionScreen.introductionSteps[widget.currentStepIndex];

    Widget contentWidget = EnrollmentLayout(
      hero: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: IntroductionArt(
              // A fresh key per step replays the entrance of the art.
              key: ValueKey(widget.currentStepIndex),
              step: widget.currentStepIndex,
            ),
          ),
        ),
      ),
      instruction: EnrollmentInstruction(
        stepIndex: onboardingV2 ? null : widget.currentStepIndex,
        stepCount: onboardingV2
            ? null
            : IntroductionScreen.introductionSteps.length,
        titleTranslationKey: step.titleTranslationKey,
        explanationTranslationKey: step.explanationTranslationKey,
        onContinue: widget.onContinue,
        onPrevious: widget.currentStepIndex != 0 ? widget.onPrevious : null,
      ),
    );

    if (!skipAnimation) {
      contentWidget = IntroductionAnimationWrapper(child: contentWidget);
    }

    return Scaffold(
      backgroundColor: YiviPalette.of(context).background,
      body: SafeArea(child: contentWidget),
    );
  }
}
