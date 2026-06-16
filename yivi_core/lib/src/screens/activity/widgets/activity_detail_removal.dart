import "package:flutter/material.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/section_header.dart";

class ActivityDetailRemoval extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailRemoval({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final removedCredentials = logEntry.removalLog?.credentials ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader("activity.deleted_data"),
        SizedBox(height: context.yivi.smallSpacing),
        for (var removedCredential in removedCredentials)
          Padding(
            padding: EdgeInsets.only(top: context.yivi.smallSpacing),
            child: YiviCredentialCard.fromLogCredential(
              logCredential: removedCredential,
              compact: true,
              hideFooter: true,
            ),
          ),
      ],
    );
  }
}
