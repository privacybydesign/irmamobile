import "package:flutter/material.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/section_header.dart";

class ActivityDetailIssuance extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailIssuance({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final issuanceLog = logEntry.issuanceLog!;
    final requestor = issuanceLog.issuer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //If is this issuance also has disclosed attributes
        if (issuanceLog.disclosedCredentials.isNotEmpty) ...[
          SectionHeader("activity.data_shared"),
          SizedBox(height: context.yivi.spacing.small),
          for (final cred in issuanceLog.disclosedCredentials)
            Padding(
              padding: EdgeInsets.only(bottom: context.yivi.spacing.small),
              child: YiviCredentialCard.fromLogCredential(
                logCredential: cred,
                compact: true,
                hideFooter: true,
              ),
            ),
          SizedBox(height: context.yivi.spacing.large),
          SectionHeader("activity.shared_with"),
          SizedBox(height: context.yivi.spacing.small),
          RequestorHeader(
            requestor: requestor,
            isVerified: requestor?.verified,
          ),
          SizedBox(height: context.yivi.spacing.large),
        ],
        SectionHeader("activity.received_data"),
        SizedBox(height: context.yivi.spacing.small),
        for (var rawCredential in issuanceLog.credentials)
          Padding(
            padding: EdgeInsets.only(bottom: context.yivi.spacing.small),
            child: YiviCredentialCard.fromLogCredential(
              logCredential: rawCredential,
              compact: true,
              hideFooter: true,
            ),
          ),
        SizedBox(height: context.yivi.spacing.base),
        SectionHeader("activity.received_from"),
        SizedBox(height: context.yivi.spacing.small),
        RequestorHeader(requestor: requestor),
      ],
    );
  }
}
