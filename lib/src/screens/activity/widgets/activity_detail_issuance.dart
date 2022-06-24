import 'package:flutter/material.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
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
          IrmaCredentialCard.fromCredential(
            Credential.fromRaw(
              irmaConfiguration: irmaConfiguration,
              rawCredential: rawCredential,
            ),
          )
      ],
    );
  }
}
