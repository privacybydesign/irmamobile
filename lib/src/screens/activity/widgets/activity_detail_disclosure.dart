import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/attributes.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/translated_text.dart';
import 'issuer_verifier_header.dart';

class ActivityDetailDisclosure extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailDisclosure({required this.logEntry, required this.irmaConfiguration});
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.shared_with',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
          child: IssuerVerifierHeader(
            title: logEntry.serverName!.name.translate(
              FlutterI18n.currentLocale(context)!.languageCode,
            ),
            logo: logEntry.serverName?.logo,
          ),
        ),
        TranslatedText(
          'activity.data_shared',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var disclosedAttributes in logEntry.disclosedAttributes)
          IrmaCredentialCard.fromAttributes(
            disclosedAttributes.map((e) => Attribute.fromDisclosedAttribute(irmaConfiguration, e)).toList(),
          ),
        if (logEntry.type == LogEntryType.signing) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: TranslatedText(
              'activity.signed_message',
              style: theme.themeData.textTheme.headline3,
            ),
          ),
          IrmaQuote(quote: logEntry.signedMessage?.message),
        ]
      ],
    );
  }
}
