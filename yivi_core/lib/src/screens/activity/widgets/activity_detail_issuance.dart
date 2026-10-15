import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "activity_detail_parts.dart";

/// An issuance: who it came from, what was received, and what was shared
/// with the issuer first (if anything).
class ActivityDetailIssuance extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailIssuance({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final issuanceLog = logEntry.issuanceLog!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityPartyCard(logEntry: logEntry),
        ActivitySection(
          titleKey: "activity.received_data",
          children: [
            for (final credential in issuanceLog.credentials)
              ActivityCredentialTile(credential: credential),
          ],
        ),
        // The issuer asked for data before issuing.
        if (issuanceLog.disclosedCredentials.isNotEmpty)
          ActivitySection(
            titleKey: "activity.shared_data",
            children: [
              for (final credential in issuanceLog.disclosedCredentials)
                ActivityCredentialTile(
                  credential: credential,
                  disclosure: true,
                ),
            ],
          ),
        const ActivityFootnote(kind: ActivityKind.received),
      ],
    );
  }
}
