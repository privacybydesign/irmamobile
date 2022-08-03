import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_markdown.dart';
import '../../../../widgets/irma_text_button.dart';
import '../../../../widgets/translated_text.dart';

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
            TranslatedText(
              titleTranslationKey,
              style: theme.textTheme.headline1,
            ),
            TranslatedText(explanationTranslationKey),
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
                Flexible(
                  child: IrmaMarkdown(
                    FlutterI18n.translate(
                      context,
                      'enrollment.terms_and_conditions.accept_markdown',
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                    child: IrmaTextButton(
                  label: 'ui.previous',
                  textStyle: theme.hyperlinkTextStyle,
                  onPressed: onPrevious,
                )),
                Flexible(
                  child: IrmaButton(
                    label: 'ui.next',
                    onPressed: isAccepted ? () => onContinue() : null,
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
