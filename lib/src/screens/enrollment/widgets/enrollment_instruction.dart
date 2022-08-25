import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import 'enrollment_nav_bar.dart';

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
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).size.height < 450;

    return SafeArea(
      top: isLandscape,
      bottom: isLandscape,
      child: Stack(
        children: [
          // Instruction content
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: theme.mediumSpacing,
              horizontal: theme.mediumSpacing,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stepIndex != null && stepCount != null)
                  Text(
                    (stepIndex! + 1).toString() + '/' + stepCount.toString(),
                    style: theme.textTheme.caption,
                  ),
                SizedBox(
                  height: theme.smallSpacing,
                ),
                TranslatedText(
                  titleTranslationKey,
                  style: theme.textTheme.headline1,
                ),
                SizedBox(
                  height: theme.defaultSpacing,
                ),
                TranslatedText(explanationTranslationKey),
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
      ),
    );
  }
}
