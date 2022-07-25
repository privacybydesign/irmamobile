import 'package:flutter/material.dart';

import '../../../models/attributes.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/translated_text.dart';
import 'activity_verifier_card.dart';

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

    return IrmaCredentialCard(
      credentialInfo: mappedAttributes.first.credentialInfo,
      attributes: mappedAttributes,
      hideFooter: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.data_shared',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var disclosedAttributes in logEntry.disclosedAttributes)
          _buildCredentialCard(
            context,
            disclosedAttributes,
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
        ],
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'activity.shared_with',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        ActivityVerifierHeader(requestorInfo: logEntry.serverName!),
      ],
    );
  }
}
