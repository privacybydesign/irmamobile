import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/log_entry.dart';

import '../../../models/attributes.dart';
import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/attributes_card.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/translated_text.dart';
import 'issuer_verifier_header.dart';

class ActivityDetailSigning extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailSigning({required this.logEntry, required this.irmaConfiguration});
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
        SizedBox(height: theme.smallSpacing),
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
          'activity.shared_data',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var disclosedAttributes in logEntry.disclosedAttributes)
          AttributesCard(
              disclosedAttributes.map((e) => Attribute.fromDisclosedAttribute(irmaConfiguration, e)).toList()),
        SizedBox(height: theme.smallSpacing),
        TranslatedText(
          'activity.signed_message',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        IrmaQuote(quote: logEntry.signedMessage?.message),
      ],
    );
  }
}
