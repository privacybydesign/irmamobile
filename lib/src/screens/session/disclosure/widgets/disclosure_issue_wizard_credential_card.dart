import 'package:flutter/material.dart';

import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';

// TODO This class should be refactored,
// so that it  only takes in one credential
class DisclosureIssueWizardCredentialCard extends StatelessWidget {
  final List<DisclosureCredential> credentials;
  final bool isActive;
  final bool highlightAttributes;

  const DisclosureIssueWizardCredentialCard({
    required this.credentials,
    this.isActive = false,
    this.highlightAttributes = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaCredentialsCard(
      style: isActive ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
      attributesByCredential: {
        for (var cred in credentials) cred: highlightAttributes == true ? cred.attributes : [],
      },
    );
  }
}
