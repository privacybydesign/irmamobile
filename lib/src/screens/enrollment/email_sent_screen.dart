import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';

class EmailSentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.email_sent.title'),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'enrollment.email_sent.button'),
        onPrimaryPressed: () {
          //
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          child: Column(
            children: <Widget>[
              IrmaMessage(
                FlutterI18n.translate(context, 'enrollment.email_sent.message_title'),
                FlutterI18n.translate(context, 'enrollment.email_sent.message_markdown'),
                iconColor: IrmaTheme.of(context).primaryBlue,
              ),
              SizedBox(
                height: IrmaTheme.of(context).defaultSpacing,
              ),
              SizedBox(
                  width: double.infinity, // seems necessary to left-align short texts
                  child: Container(
                    child: TranslatedText('enrollment.email_sent.mail_sent_text_markdown'),
                  )),
              SizedBox(
                height: IrmaTheme.of(context).defaultSpacing,
              ),
              const TranslatedText('enrollment.email_sent.check_spam'),
            ],
          ),
        ),
      ),
    );
  }
}
