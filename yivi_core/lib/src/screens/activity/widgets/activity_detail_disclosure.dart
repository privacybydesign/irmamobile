import "package:flutter/material.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/irma_empty_credential_card.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_quote.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/section_header.dart";

class ActivityDetailDisclosure extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailDisclosure({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader("activity.data_shared"),
        SizedBox(height: context.yivi.smallSpacing),
        // If all disclosed attributes are empty render one empty data card
        if (noDisclosedCredentials(logEntry))
          IrmaEmptyCredentialCard()
        else
          for (var credential
              in logEntry.type == LogType.disclosure
                  ? logEntry.disclosureLog!.credentials
                  : logEntry.signedMessageLog!.credentials)
            Padding(
              padding: EdgeInsets.only(bottom: context.yivi.smallSpacing),
              child: YiviCredentialCard.fromLogCredential(
                logCredential: credential,
                compact: true,
                hideFooter: true,
              ),
            ),
        if (logEntry.type == LogType.signature) ...[
          SizedBox(height: context.yivi.defaultSpacing),
          SectionHeader("activity.signed_message"),
          SizedBox(height: context.yivi.smallSpacing),
          IrmaQuote(quote: logEntry.signedMessageLog!.message),
        ],
        SizedBox(height: context.yivi.defaultSpacing),
        SectionHeader("activity.shared_with"),
        SizedBox(height: context.yivi.smallSpacing),
        RequestorHeader(requestor: logEntry.requestor),
      ],
    );
  }

  bool noDisclosedCredentials(LogInfo info) {
    return info.type == LogType.disclosure
        ? info.disclosureLog!.credentials.isEmpty
        : info.signedMessageLog!.credentials.isEmpty;
  }
}
