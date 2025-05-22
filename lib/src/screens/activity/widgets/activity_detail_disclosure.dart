import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/attribute.dart';
import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/credential_card/irma_empty_credential_card.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/issuer_verifier_header.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailDisclosure extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailDisclosure({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  Widget _buildCredentialCard(
    BuildContext context,
    List<DisclosedAttribute> disclosedAttributes,
  ) {
    final mappedAttributes =
        disclosedAttributes.map((e) => Attribute.fromDisclosedAttribute(irmaConfiguration, e)).toList();
    final credentialView = CredentialView.fromAttributes(
      irmaConfiguration: irmaConfiguration,
      attributes: mappedAttributes,
    );

    return IrmaCredentialCard(
      credentialFormat: 'unknown',
      credentialView: credentialView,
      hideFooter: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final groupedDisclosedAttributes = logEntry.disclosedAttributes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.data_shared',
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        // If all disclosed attributes are empty render one empty data card
        if (groupedDisclosedAttributes.every(
          (disclosedAttributes) => disclosedAttributes.isEmpty,
        ))
          IrmaEmptyCredentialCard()
        // Else build credential cards for all the
        // disclosedAttributes that are not empty
        else
          for (var disclosedAttributes in groupedDisclosedAttributes.where(
            (disclosedAttributes) => disclosedAttributes.isNotEmpty,
          ))
            _buildCredentialCard(
              context,
              disclosedAttributes,
            ),
        if (logEntry.type == LogEntryType.signing) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: TranslatedText(
              'activity.signed_message',
              style: theme.themeData.textTheme.headlineMedium,
              isHeader: true,
            ),
          ),
          IrmaQuote(quote: logEntry.signedMessage?.message),
        ],
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'activity.shared_with',
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        IssuerVerifierHeader(
          title: logEntry.serverName?.name.translate(
            FlutterI18n.currentLocale(context)!.languageCode,
          ),
          titleTextStyle: IrmaTheme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          imagePath: logEntry.serverName?.logoPath,
        )
      ],
    );
  }
}
