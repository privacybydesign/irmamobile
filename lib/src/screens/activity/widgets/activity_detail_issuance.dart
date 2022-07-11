import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../util/date_formatter.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/translated_text.dart';
import 'activity_detail_disclosure.dart';

class ActivityDetailIssuance extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailIssuance({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    IrmaCredentialCard _buildCredentialCard(Credential credential) {
      return IrmaCredentialCard.fromCredential(
        credential,
        trailingText: TranslatedText(
          'credential.valid_until',
          translationParams: {
            'date': printableDate(credential.expires, lang),
          },
          style: theme.textTheme.caption!.copyWith(
            color: theme.neutral,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //If is this issuance also has disclosed attributes
        if (logEntry.disclosedAttributes.isNotEmpty) ...[
          ActivityDetailDisclosure(
            logEntry: logEntry,
            irmaConfiguration: irmaConfiguration,
          ),
          SizedBox(height: theme.smallSpacing),
        ],
        TranslatedText(
          'activity.received_data',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var rawCredential in logEntry.issuedCredentials)
          _buildCredentialCard(
            Credential.fromRaw(
              irmaConfiguration: irmaConfiguration,
              rawCredential: rawCredential,
            ),
          )
      ],
    );
  }
}
