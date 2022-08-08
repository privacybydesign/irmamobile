import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_text_button.dart';
import '../../../widgets/translated_text.dart';

class EnrollmentInstruction extends StatelessWidget {
  final int? stepIndex;
  final int? stepCount;
  final String titleTranslationKey;
  final String explanationTranslationKey;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

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
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).size.height < 450;

    return SafeArea(
      top: isLandscape,
      bottom: isLandscape,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.mediumSpacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stepIndex != null && stepCount != null)
                  Text(
                    (stepIndex! + 1).toString() + '/' + stepCount.toString(),
                    style: theme.textTheme.caption,
                  ),
                TranslatedText(
                  titleTranslationKey,
                  style: theme.textTheme.headline1,
                ),
              ],
            ),
            TranslatedText(explanationTranslationKey),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: stepIndex != 0
                      ? IrmaTextButton(
                          label: 'ui.previous',
                          textStyle: theme.hyperlinkTextStyle,
                          onPressed: onPrevious,
                        )
                      : Container(),
                ),
                Flexible(
                  child: IrmaButton(
                    label: 'ui.next',
                    onPressed: onContinue,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
