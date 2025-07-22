import 'package:flutter/material.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailRemoval extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailRemoval({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final removedCredentials = logEntry.removedCredentials.entries
        .map((entry) => CredentialView.fromRawAttributes(
              irmaConfiguration: irmaConfiguration,
              rawAttributes: entry.value,
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.deleted_data',
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var removedCredential in removedCredentials)
          Padding(
            padding: EdgeInsets.only(top: theme.smallSpacing),
            child: IrmaCredentialCard(
              credentialFormats: [],
              credentialView: removedCredential,
              hideFooter: true,
            ),
          )
      ],
    );
  }
}
