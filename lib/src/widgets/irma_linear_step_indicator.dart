import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_linear_progresss_indicator.dart';
import 'translated_text.dart';

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
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TranslatedText(
            'ui.step_of_steps',
            translationParams: {
              'i': step.toString(),
              'n': stepCount.toString(),
            },
            style: TextStyle(
              fontSize: 12,
              color: theme.themeData.colorScheme.secondary,
            ),
          ),
          SizedBox(height: theme.smallSpacing),
          IrmaLinearProgressIndicator(
            filledPercentage: step / stepCount * 100,
          )
        ],
      ),
    );
  }
}
