import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/attributes.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/attributes_card.dart';
import '../../../widgets/translated_text.dart';
import 'issuer_verifier_header.dart';

class ActivityDetailDisclose extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailDisclose({required this.logEntry, required this.irmaConfiguration});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.shared_with',
          style: IrmaTheme.of(context).themeData.textTheme.headline3,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        Padding(
          padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
          child: IssuerVerifierHeader(
            title: logEntry.serverName!.name.translate(
              FlutterI18n.currentLocale(context)!.languageCode,
            ),
            logo: logEntry.serverName?.logo,
          ),
        ),
        TranslatedText(
          'activity.data_shared',
          style: IrmaTheme.of(context).themeData.textTheme.headline3,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        for (var disclosedAttributes in logEntry.disclosedAttributes)
          AttributesCard(
              disclosedAttributes.map((e) => Attribute.fromDisclosedAttribute(irmaConfiguration, e)).toList())
      ],
    );
  }
}
