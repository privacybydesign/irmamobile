import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_close_button.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/translated_text.dart';
import '../../home/home_screen.dart';

class EmailSentScreen extends StatelessWidget {
  static const String routeName = 'email_sent_screen';

  final String email;
  final VoidCallback onContinue;

  const EmailSentScreen({
    Key? key,
    required this.email,
    required this.onContinue,
  }) : super(key: key);

  _navigateToHome(BuildContext context) => Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed(HomeScreen.routeName);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      key: const Key('email_sent_screen'),
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.email.confirm.title',
        noLeading: true,
        actions: [
          IrmaCloseButton(
            onTap: () => _navigateToHome(context),
          )
        ],
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'ui.next'),
        onPrimaryPressed: () => _navigateToHome(context),
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
                      style: theme.textTheme.bodyText1,
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
