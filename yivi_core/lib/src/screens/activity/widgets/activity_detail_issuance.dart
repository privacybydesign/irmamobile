import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/section_header.dart";

class ActivityDetailIssuance extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailIssuance({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final issuanceLog = logEntry.issuanceLog!;
    final requestor = issuanceLog.issuer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //If is this issuance also has disclosed attributes
        if (issuanceLog.disclosedCredentials.isNotEmpty) ...[
          SectionHeader("activity.data_shared"),
          SizedBox(height: theme.smallSpacing),
          for (final cred in issuanceLog.disclosedCredentials)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: YiviCredentialCard.fromLogCredential(
                logCredential: cred,
                compact: true,
                hideFooter: true,
              ),
            ),
          SizedBox(height: theme.defaultSpacing),
          SectionHeader("activity.shared_with"),
          SizedBox(height: theme.smallSpacing),
          // Data left the wallet in this session, so the party is judged on the
          // verifier's bar even though the session was an issuance.
          RequestorHeader(
            requestor: requestor,
            sessionType: SessionType.disclosure,
          ),
          SizedBox(height: theme.defaultSpacing),
        ],
        SectionHeader("activity.received_data"),
        SizedBox(height: theme.smallSpacing),
        for (var rawCredential in issuanceLog.credentials)
          Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: YiviCredentialCard.fromLogCredential(
              logCredential: rawCredential,
              compact: true,
              hideFooter: true,
            ),
          ),
        SizedBox(height: theme.defaultSpacing),
        SectionHeader("activity.received_from"),
        SizedBox(height: theme.smallSpacing),
        RequestorHeader(requestor: requestor),
      ],
    );
  }
}
