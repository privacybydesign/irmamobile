import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "../../../widgets/translated_text.dart";

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
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      key: const Key("email_sent_screen"),
      appBar: IrmaAppBar(
        titleTranslationKey: "enrollment.email.confirm.title",
        leading: null,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "ui.next"),
        onPrimaryPressed: onContinue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.yivi.defaultSpacing,
            vertical: context.yivi.defaultSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IrmaQuote(
                quote: "enrollment.email.confirm.explanation_extra_markdown",
              ),
              SizedBox(height: context.yivi.defaultSpacing),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${FlutterI18n.translate(context, 'enrollment.email.confirm.header')} ',
                    ),
                    TextSpan(text: "$email ", style: context.text.bodyLarge),
                  ],
                ),
              ),
              SizedBox(height: context.yivi.smallSpacing),
              const TranslatedText("enrollment.email.confirm.explanation"),
            ],
          ),
        ),
      ),
    );
  }
}
