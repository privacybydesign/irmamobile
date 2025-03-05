import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/translated_text.dart';

class EmailSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onContinue;

  const EmailSentScreen({
    super.key,
    required this.email,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      key: const Key('email_sent_screen'),
      appBar: const IrmaAppBar(
        titleTranslationKey: 'enrollment.email.confirm.title',
        leading: null,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'ui.next'),
        onPrimaryPressed: onContinue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing, vertical: theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IrmaQuote(
                quote: 'enrollment.email.confirm.explanation_extra_markdown',
              ),
              SizedBox(
                height: theme.defaultSpacing,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${FlutterI18n.translate(
                        context,
                        'enrollment.email.confirm.header',
                      )} ',
                    ),
                    TextSpan(
                      text: '$email ',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: theme.smallSpacing,
              ),
              const TranslatedText('enrollment.email.confirm.explanation')
            ],
          ),
        ),
      ),
    );
  }
}
