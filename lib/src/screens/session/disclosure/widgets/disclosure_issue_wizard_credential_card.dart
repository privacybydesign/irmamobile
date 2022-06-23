import 'package:flutter/material.dart';

import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';

class DisclosureIssueWizardCredentialCards extends StatelessWidget {
  final List<DisclosureCredential> credentials;
  final bool isActive;
  final bool showAttributes;

  const DisclosureIssueWizardCredentialCards({
    required this.credentials,
    this.isActive = false,
    this.showAttributes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: credentials
          .map(
            (credentialInfo) => IrmaCredentialCard(
              credentialInfo: credentialInfo,
              attributes: showAttributes ? credentialInfo.attributes : [],
              style: isActive ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
              compareTo: credentialInfo.attributes,
            ),
          )
          .toList(),
    );
  }
}
