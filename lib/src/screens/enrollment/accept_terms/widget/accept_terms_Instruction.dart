import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_text_button.dart';
import '../../../../widgets/translated_text.dart';

class AcceptTermsInstruction extends StatelessWidget {
  final String titleTranslationKey;
  final String explanationTranslationKey;

  final bool isAccepted;
  final Function(bool) onToggleAccepted;
  final VoidCallback onContinue;

  const AcceptTermsInstruction({
    required this.titleTranslationKey,
    required this.explanationTranslationKey,
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
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
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${FlutterI18n.translate(context, 'enrollment.terms_and_conditions.accept')} ',
                          style: theme.textTheme.caption,
                        ),
                        TextSpan(
                          text: '${FlutterI18n.translate(context, 'enrollment.terms_and_conditions.terms')} ',
                          style: theme.hyperlinkTextStyle.copyWith(fontSize: theme.textTheme.caption!.fontSize),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launch(
                                  FlutterI18n.translate(
                                    context,
                                    'enrollment.terms_and_conditions.link',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                    child: IrmaTextButton(
                  label: 'ui.previous',
                  textStyle: theme.hyperlinkTextStyle,
                  onPressed: () {},
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
