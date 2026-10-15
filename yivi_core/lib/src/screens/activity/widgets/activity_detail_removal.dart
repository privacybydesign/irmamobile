import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "activity_detail_parts.dart";

/// A removal: whose data was deleted, and the deleted cards, washed out.
class ActivityDetailRemoval extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailRemoval({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final removedCredentials = logEntry.removalLog?.credentials ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityPartyCard(logEntry: logEntry),
        ActivitySection(
          titleKey: "activity.deleted_data",
          children: [
            for (final credential in removedCredentials)
              ActivityCredentialTile(credential: credential, faded: true),
          ],
        ),
        const ActivityFootnote(kind: ActivityKind.deleted),
      ],
    );
  }
}
