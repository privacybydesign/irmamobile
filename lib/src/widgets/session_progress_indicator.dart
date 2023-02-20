import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_card.dart';
import 'irma_linear_progresss_indicator.dart';
import 'translated_text.dart';

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
  })  : assert(
          step == null || stepCount != null,
          'A stepCount is required when providing a step',
        ),
        assert(
          stepCount == null || step != null,
          'A step is required when providing a stepCount',
        );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final showProgress = step != null && stepCount != null && stepCount != 1;

    return IrmaCard(
      padding: EdgeInsets.symmetric(
        vertical: theme.defaultSpacing,
      ),
      style: IrmaCardStyle.highlighted,
      margin: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) ...[
            TranslatedText(
              'ui.step_of_steps',
              translationParams: {
                'i': step.toString(),
                'n': stepCount.toString(),
              },
              style: theme.themeData.textTheme.bodyText2!.copyWith(
                fontSize: 14,
                color: theme.neutralExtraDark,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
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
                    style: theme.themeData.textTheme.headline4!.copyWith(
                      color: theme.dark,
                    ),
                  ),
                )
              ],
            )
        ],
      ),
    );
  }
}
