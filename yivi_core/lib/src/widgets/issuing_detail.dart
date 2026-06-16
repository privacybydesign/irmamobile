import "package:flutter/material.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../theme/theme.dart";
import "credential_card/yivi_credential_card.dart";

class IssuingDetail extends StatelessWidget {
  final List<schemaless.Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: credentials.map((credential) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.yivi.defaultSpacing),
          child: YiviCredentialCard.fromCredential(
            credential: credential,
            compact: false,
            lowInstanceCountThreshold: 0,
          ),
        );
      }).toList(),
    );
  }
}
