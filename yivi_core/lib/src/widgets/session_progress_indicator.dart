import "package:flutter/material.dart";

import "../theme/theme.dart";
import "irma_card.dart";
import "irma_linear_progresss_indicator.dart";
import "translated_text.dart";

class SessionProgressIndicator extends StatelessWidget {
  final int? step;
  final int? stepCount;
  final String? contentTranslationKey;
  final Map<String, String>? contentTranslationParams;

  const SessionProgressIndicator({
    this.step,
    this.stepCount,
    this.contentTranslationKey,
    this.contentTranslationParams,
  }) : assert(
         step == null || stepCount != null,
         "A stepCount is required when providing a step",
       ),
       assert(
         stepCount == null || step != null,
         "A step is required when providing a stepCount",
       );

  @override
  Widget build(BuildContext context) {
    final showProgress = step != null && stepCount != null && stepCount != 1;

    return IrmaCard(
      hasShadow: false,
      padding: EdgeInsets.symmetric(vertical: context.yivi.spacing.base),
      style: IrmaCardStyle.highlighted,
      margin: EdgeInsets.all(context.yivi.spacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) ...[
            TranslatedText(
              "ui.step_of_steps",
              translationParams: {
                "i": step.toString(),
                "n": stepCount.toString(),
              },
              style: context.text.bodySmall,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.yivi.spacing.small,
              ),
              child: IrmaLinearProgressIndicator(
                filledPercentage: step! / stepCount! * 100,
              ),
            ),
          ],
          if (contentTranslationKey != null)
            Row(
              children: [
                Flexible(
                  child: TranslatedText(
                    contentTranslationKey!,
                    translationParams: contentTranslationParams,
                    // bodyLarge — this is the card's primary content text,
                    // not a title or subsection label.
                    style: context.text.bodyLarge,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
