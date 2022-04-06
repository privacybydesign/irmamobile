import 'package:flutter/material.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/attributes_card.dart';
import '../../../widgets/credential_card/irma_credential_card.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailRemoval extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailRemoval({required this.logEntry, required this.irmaConfiguration});
  @override
  Widget build(BuildContext context) {
    final removedCredentials = logEntry.removedCredentials.entries
        .map<RemovedCredential>((entry) => RemovedCredential.fromRaw(
              irmaConfiguration: irmaConfiguration,
              credentialIdentifier: entry.key,
              rawAttributes: entry.value,
            ))
        .toList();

    return Column(
      children: [
        TranslatedText(
          'activity.deleted_data',
          style: IrmaTheme.of(context).themeData.textTheme.headline3,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        for (var removedCredential in removedCredentials)
          Padding(
              padding: EdgeInsets.only(top: IrmaTheme.of(context).smallSpacing),
              child: IrmaCredentialCard.fromAttributes(removedCredential.attributeList))
      ],
    );
  }
}
