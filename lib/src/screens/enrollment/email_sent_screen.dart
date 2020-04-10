import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';

class EmailSentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        title: Text("Beveiliging instellen"),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'Doorgaan',
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
                "Bevestig je e-mailadres",
                "Je hebt een email ontvangen van noreply@sidn.nl. Open de link in de mail om je e-mailadres an je IRMA app te koppelen.",
                iconColor: IrmaTheme.of(context).primaryBlue,
              ),
              SizedBox(
                height: IrmaTheme.of(context).defaultSpacing,
              ),
              const TranslatedText("Er is een e-mail gestuurd naar: hanna@sent.com."),
              SizedBox(
                height: IrmaTheme.of(context).defaultSpacing,
              ),
              const TranslatedText(
                  "Het kan even duren voordat de email binnen is. Controleer de spamfolder als je geen email hebt ontvangen."),
            ],
          ),
        ),
      ),
    );
  }
}
