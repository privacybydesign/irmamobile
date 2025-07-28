import 'package:flutter/material.dart';

import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';
import '../models/template_disclosure_credential.dart';

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
      children: credentials.map(
        (cred) {
          final isDisabled = cred is TemplateDisclosureCredential && !cred.obtainable;
          return IrmaCredentialCard(
            hashByFormat: {},
            style: isActive && !isDisabled ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
            compareTo: cred.attributes,
            hideAttributes: hideAttributes,
            hideFooter: !isActive,
            disabled: isDisabled,
            type: cred.credentialType,
            issuer: cred.issuer,
            attributes: cred.attributes,
            valid: cred.valid,
            expired: cred.expired,
            revoked: cred.revoked,
            isTemplate: cred is TemplateDisclosureCredential,
          );
        },
      ).toList(),
    );
  }
}
