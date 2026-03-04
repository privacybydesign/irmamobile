import "package:flutter/material.dart";

import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../theme/theme.dart";
import "credential_card/schemaless_yivi_credential_card.dart";

class IssuingDetail extends StatelessWidget {
  final List<schemaless.Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Column(
      children: credentials.map((credential) {
        return Padding(
          padding: EdgeInsets.only(bottom: theme.defaultSpacing),
          child: SchemalessYiviCredentialCard(
            credential: credential,
            compact: false,
            lowInstanceCountThreshold: 0,
          ),
        );
      }).toList(),
    );
  }
}
