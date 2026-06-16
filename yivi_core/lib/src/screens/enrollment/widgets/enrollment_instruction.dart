import "package:flutter/material.dart";
import "package:flutter/widgets.dart";

import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_progress_indicator.dart";
import "enrollment_nav_bar.dart";

class EnrollmentInstruction extends StatelessWidget {
  final int? stepIndex;
  final int? stepCount;
  final String titleTranslationKey;
  final String explanationTranslationKey;
  final VoidCallback onContinue;
  final VoidCallback? onPrevious;

  const EnrollmentInstruction({
    this.stepIndex,
    this.stepCount,
    required this.titleTranslationKey,
    required this.explanationTranslationKey,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // Instruction content
        SingleChildScrollView(
          padding: EdgeInsets.all(context.yivi.spacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLandscape) SizedBox(height: context.yivi.spacing.base),
              if (stepIndex != null && stepCount != null)
                YiviProgressIndicator(
                  stepCount: stepCount!,
                  stepIndex: stepIndex!,
                ),
              SizedBox(height: context.yivi.spacing.small),
              TranslatedText(
                titleTranslationKey,
                style: context.text.displayLarge,
              ),
              SizedBox(height: context.yivi.spacing.base),
              TranslatedText(explanationTranslationKey),
              // Extra white space so the content above always stays visible
              SizedBox(
                height: context.yivi.spacing.base + context.yivi.spacing.huge,
              ),
            ],
          ),
        ),

        // Bottom continue/previous bar
        Align(
          alignment: Alignment.bottomCenter,
          child: EnrollmentNavBar(
            onPrevious: onPrevious,
            onContinue: onContinue,
          ),
        ),
      ],
    );
  }
}
