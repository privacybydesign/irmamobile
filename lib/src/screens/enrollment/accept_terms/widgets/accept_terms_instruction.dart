import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';
import '../../widgets/enrollment_nav_bar.dart';

class AcceptTermsInstruction extends StatelessWidget {
  final String titleTranslationKey;
  final String explanationTranslationKey;

  final bool isAccepted;
  final Function(bool) onToggleAccepted;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const AcceptTermsInstruction({
    required this.titleTranslationKey,
    required this.explanationTranslationKey,
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      top: isLandscape,
      bottom: isLandscape,
      child: Stack(
        children: [
          // Instruction content
          SingleChildScrollView(
            padding: EdgeInsets.all(theme.mediumSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  titleTranslationKey,
                  style: theme.textTheme.headline1,
                ),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(explanationTranslationKey),
                SizedBox(
                  height: theme.defaultSpacing,
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isAccepted,
                      fillColor: MaterialStateColor.resolveWith((_) => theme.themeData.colorScheme.secondary),
                      onChanged: (isAccepted) => onToggleAccepted(
                        isAccepted ?? false,
                      ),
                    ),
                    SizedBox(
                      width: theme.smallSpacing,
                    ),
                    const Flexible(
                      child: TranslatedText(
                        'enrollment.terms_and_conditions.accept_markdown',
                      ),
                    ),
                  ],
                ),

                // Extra white space so the content above always stays visible
                SizedBox(
                  height: theme.defaultSpacing + theme.hugeSpacing,
                ),
              ],
            ),
          ),

          // Bottom continue/previous bar
          Align(
            alignment: Alignment.bottomCenter,
            child: EnrollmentNavBar(
              onPrevious: onPrevious,
              onContinue: isAccepted ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
