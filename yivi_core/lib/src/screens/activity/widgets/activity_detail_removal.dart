import "package:flutter/material.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/translated_text.dart";

class ActivityDetailRemoval extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailRemoval({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final removedCredentials = logEntry.removalLog?.credentials ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          "activity.deleted_data",
          style: theme.themeData.textTheme.headlineMedium,
          isHeader: true,
        ),
        SizedBox(height: theme.smallSpacing),
        for (var removedCredential in removedCredentials)
          Padding(
            padding: EdgeInsets.only(top: theme.smallSpacing),
            child: YiviCredentialCard(
              credential: removedCredential.toCredential(),
              compact: true,
            ),
          ),
      ],
    );
  }
}
