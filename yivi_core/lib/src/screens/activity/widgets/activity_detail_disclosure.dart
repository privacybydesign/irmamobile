import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../widgets/credential_card/irma_empty_credential_card.dart";
import "activity_detail_parts.dart";

/// A disclosure or a signed message: who it was for, the message, and the
/// shared attributes per credential.
class ActivityDetailDisclosure extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailDisclosure({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final kind = ActivityKind.of(logEntry);
    final credentials = logEntry.type == LogType.disclosure
        ? logEntry.disclosureLog!.credentials
        : logEntry.signedMessageLog!.credentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityPartyCard(logEntry: logEntry),
        if (logEntry.type == LogType.signature)
          ActivitySection(
            titleKey: "activity.signed_message",
            children: [
              ActivitySignedMessage(
                message: logEntry.signedMessageLog!.message,
              ),
            ],
          ),
        ActivitySection(
          titleKey: kind.titleKey,
          children: [
            // Nothing was disclosed: one empty data card.
            if (credentials.isEmpty)
              IrmaEmptyCredentialCard()
            else
              for (final credential in credentials)
                ActivityCredentialTile(
                  credential: credential,
                  disclosure: true,
                ),
          ],
        ),
        ActivityFootnote(kind: kind),
      ],
    );
  }
}
