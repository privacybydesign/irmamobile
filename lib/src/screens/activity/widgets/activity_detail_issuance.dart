import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailIssuance extends StatelessWidget {
  final LogInfo logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailIssuance({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final issuanceLog = logEntry.issuanceLog!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //If is this issuance also has disclosed attributes
        if (issuanceLog.disclosedCredentials.isNotEmpty) ...[
          for (final cred in issuanceLog.disclosedCredentials)
            Padding(
              padding: EdgeInsets.only(top: theme.smallSpacing),
              child: IrmaCredentialCard.fromCredentialLog(irmaConfiguration, cred),
            ),
          SizedBox(height: theme.smallSpacing),
        ],
        TranslatedText(
          'activity.received_data',
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var rawCredential in issuanceLog.credentials)
          Padding(
            padding: EdgeInsets.only(top: theme.smallSpacing),
            child: IrmaCredentialCard.fromCredentialLog(
              irmaConfiguration,
              rawCredential,
            ),
          )
      ],
    );
  }
}
