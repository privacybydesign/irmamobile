import 'package:flutter/material.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/card/attributes_card.dart';
import '../../../widgets/translated_text.dart';

class ActivityDetailIssuance extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailIssuance({required this.logEntry, required this.irmaConfiguration});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'activity.received_data',
          style: IrmaTheme.of(context).themeData.textTheme.headline3,
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        for (var rawCredential in logEntry.issuedCredentials)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AttributesCard(
              Credential.fromRaw(
                irmaConfiguration: irmaConfiguration,
                rawCredential: rawCredential,
              ).attributeList,
            ),
          ),
      ],
    );
  }
}
