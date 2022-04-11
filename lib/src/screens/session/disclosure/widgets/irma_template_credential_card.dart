import 'package:flutter/material.dart';

import '../../../../util/language.dart';
import '../../../../widgets/credential_card/card_credential_header.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../models/template_disclosure_credential.dart';

class IrmaCredentialTemplateCard extends StatelessWidget {
  final TemplateDisclosureCredential credential;

  const IrmaCredentialTemplateCard(this.credential);

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      onTap: () => credential.obtained
          ? null
          : IrmaRepositoryProvider.of(context).openIssueURL(context, credential.credentialType.fullId),
      dottedBorder: !credential.obtained,
      child: Column(
        children: [
          CardCredentialHeader(
            type: credential.obtained ? CredentialHeaderType.success : CredentialHeaderType.template,
            credentialName: getTranslation(context, credential.credentialType.name),
            issuerName: getTranslation(context, credential.issuer.name),
          )
        ],
      ),
    );
  }
}
