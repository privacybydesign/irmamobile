import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/activity/widgets/attributes_card.dart';
import 'package:irmamobile/src/screens/activity/widgets/issuer_verifier_header.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/date_formatter.dart';
import 'package:irmamobile/src/widgets/card/card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class ActivityDetailScreen extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailScreen({required this.logEntry, required this.irmaConfiguration});

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      appBar: IrmaAppBar(
          title: TranslatedText(
        'home.nav_bar.activity',
        style: theme.themeData.textTheme.headline2,
      )),
      bottomNavigationBar:
          IrmaBottomBar(primaryButtonLabel: 'home.button_back', onPrimaryPressed: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildDetailWidgets(context),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            Center(
                child: Text(
              formatDate(logEntry.time, lang),
              style: IrmaTheme.of(context).themeData.textTheme.caption,
            ))
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailWidgets(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;
    final List<Widget> widgets = [];

    switch (logEntry.type) {
      case LogEntryType.signing:
      case LogEntryType.disclosing:
        widgets.addAll([
          _buildHeaderText(context, 'activity.shared_with'),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          Padding(
            padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
            child: IssuerVerifierHeader(
              title: logEntry.serverName!.name.translate(lang),
              logo: logEntry.serverName?.logo,
            ),
          ),
          _buildHeaderText(context, 'activity.shared_data'),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          for (var disclosedAttributes in logEntry.disclosedAttributes)
            AttributesCard(
                disclosedAttributes.map((e) => Attribute.fromDisclosedAttribute(irmaConfiguration, e)).toList())
        ]);

        if (logEntry.type == LogEntryType.signing) {
          widgets.addAll([
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            _buildHeaderText(context, 'activity.signed_message'),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            IrmaQuote(quote: logEntry.signedMessage?.message),
          ]);
        }

        break;
      case LogEntryType.removal:
      case LogEntryType.issuing:
        final removedCredentials = logEntry.removedCredentials.entries
            .map<RemovedCredential>((entry) => RemovedCredential.fromRaw(
                  irmaConfiguration: irmaConfiguration,
                  credentialIdentifier: entry.key,
                  rawAttributes: entry.value,
                ))
            .toList();

        widgets.addAll([
          _buildHeaderText(
              context, logEntry.type == LogEntryType.issuing ? 'activity.received_data' : 'activity.deleted_data'),
          for (var rawCredential in logEntry.issuedCredentials)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AttributesCard(
                  Credential.fromRaw(irmaConfiguration: irmaConfiguration, rawCredential: rawCredential).attributeList),
            ),
          for (var removedCredential in removedCredentials)
            Padding(
              padding: EdgeInsets.only(top: IrmaTheme.of(context).smallSpacing),
              child: AttributesCard(removedCredential.attributeList),
            )
        ]);
        break;
    }
    return widgets;
  }

  Widget _buildHeaderText(BuildContext context, String translationKey) => TranslatedText(
        translationKey,
        style: IrmaTheme.of(context).themeData.textTheme.headline3,
      );
}
