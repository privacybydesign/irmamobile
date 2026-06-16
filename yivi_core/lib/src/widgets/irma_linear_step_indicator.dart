import "package:flutter/material.dart";

import "../theme/theme.dart";
import "irma_linear_progresss_indicator.dart";
import "translated_text.dart";

class IrmaLinearStepIndicator extends StatelessWidget {
  final int stepCount;
  final int step;

  const IrmaLinearStepIndicator({
    super.key,
    required this.step,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.yivi.spacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TranslatedText(
            "ui.step_of_steps",
            translationParams: {
              "i": step.toString(),
              "n": stepCount.toString(),
            },
            style: context.yivi.indicator.linearStep,
          ),
          SizedBox(height: context.yivi.spacing.small),
          IrmaLinearProgressIndicator(filledPercentage: step / stepCount * 100),
        ],
      ),
    );
  }
}
