import 'package:flutter/material.dart';

import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';

class DisclosureIssueWizardCredentialCards extends StatelessWidget {
  final List<DisclosureCredential> credentials;
  final bool isActive;
  final bool hideAttributes;

  const DisclosureIssueWizardCredentialCards({
    required this.credentials,
    this.isActive = false,
    this.hideAttributes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: credentials
          .map(
            (cred) => IrmaCredentialCard(
              credentialView: cred,
              style: isActive ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
              compareTo: cred.attributes,
              hideAttributes: hideAttributes,
              hideFooter: !isActive,
            ),
          )
          .toList(),
    );
  }
}
