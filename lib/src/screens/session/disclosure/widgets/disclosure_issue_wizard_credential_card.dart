import 'package:flutter/material.dart';

import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';

class DisclosureIssueWizardCredentialCard extends StatelessWidget {
  final DisclosureCredential credential;
  final bool isActive;
  final bool highlightAttributes;

  const DisclosureIssueWizardCredentialCard({
    required this.credential,
    this.isActive = false,
    this.highlightAttributes = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaCredentialsCard(
      style: isActive ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
      attributesByCredential: {
        credential: highlightAttributes == true ? credential.attributes : [],
      },
      // Compare to self to highlight the required attribute values
      compareToCredentials: highlightAttributes == true ? [credential] : null,
    );
  }
}
