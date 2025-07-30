import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/credential_card/irma_empty_credential_card.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/issuer_verifier_header.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailDisclosure extends StatelessWidget {
  final LogInfo logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailDisclosure({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final requestor =
        logEntry.type == LogType.disclosure ? logEntry.disclosureLog!.verifier : logEntry.signedMessageLog!.verifier;

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
        if (noDisclosedCredentials(logEntry))
          IrmaEmptyCredentialCard()
        else
          for (var credential in logEntry.type == LogType.disclosure
              ? logEntry.disclosureLog!.credentials
              : logEntry.signedMessageLog!.credentials)
            IrmaCredentialCard.fromCredentialLog(
              irmaConfiguration,
              credential,
            ),
        if (logEntry.type == LogType.signature) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: TranslatedText(
              'activity.signed_message',
              style: theme.themeData.textTheme.headlineMedium,
              isHeader: true,
            ),
          ),
          IrmaQuote(quote: logEntry.signedMessageLog!.message),
        ],
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'activity.shared_with',
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        IssuerVerifierHeader(
          title: requestor.name.translate(
            FlutterI18n.currentLocale(context)!.languageCode,
          ),
          titleTextStyle: IrmaTheme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          imagePath: requestor.logoPath,
        )
      ],
    );
  }

  bool noDisclosedCredentials(LogInfo info) {
    return info.type == LogType.disclosure
        ? info.disclosureLog!.credentials.isEmpty
        : info.signedMessageLog!.credentials.isEmpty;
  }
}
