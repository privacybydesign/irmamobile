import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class EmailSentScreen extends StatelessWidget {
  static const String routeName = "EmailSentScreen";
  final String email;

  const EmailSentScreen({Key key, @required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Navigator.of(context, rootNavigator: true).pushReplacementNamed(WalletScreen.routeName),
      child: Scaffold(
        appBar: IrmaAppBar(
          key: const Key('email_sent_screen_title'),
          title: Text(
            FlutterI18n.translate(context, 'enrollment.email_sent.title'),
          ),
          noLeading: true,
        ),
        bottomNavigationBar: IrmaBottomBar(
          key: const Key("email_sent_screen_continue"),
          primaryButtonLabel: FlutterI18n.translate(context, 'enrollment.email_sent.button'),
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed(WalletScreen.routeName);
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const Key('email_sent_screen'),
            padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
            child: Column(
              children: <Widget>[
                const IrmaMessage(
                  'enrollment.email_sent.message_title',
                  'enrollment.email_sent.message',
                  type: IrmaMessageType.info,
                ),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                SizedBox(
                    width: double.infinity, // seems necessary to left-align short texts
                    child: Container(
                      child: TranslatedText('enrollment.email_sent.mail_sent_text',
                          translationParams: {"emailaddress": email}),
                    )),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                const TranslatedText('enrollment.email_sent.check_spam'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
