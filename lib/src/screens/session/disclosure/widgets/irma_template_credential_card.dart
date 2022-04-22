import 'package:flutter/material.dart';

import '../../../../util/language.dart';
import '../../../../widgets/credential_card/irma_credential_card_header.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../models/template_disclosure_credential.dart';

class IrmaCredentialTemplateCard extends StatelessWidget {
  final TemplateDisclosureCredential credential;
  final bool forceObtainable;

  const IrmaCredentialTemplateCard(this.credential, {this.forceObtainable = false});

  @override
  Widget build(BuildContext context) {
    final obtainable = forceObtainable || !credential.obtained;

    return IrmaCard(
      onTap: () => !obtainable
          ? null
          : IrmaRepositoryProvider.of(context).openIssueURL(context, credential.credentialType.fullId),
      style: obtainable ? IrmaCardStyle.template : IrmaCardStyle.normal,
      child: Column(
        children: [
          IrmaCredentialCardHeader(
            type: obtainable ? CredentialHeaderType.template : CredentialHeaderType.success,
            title: getTranslation(context, credential.credentialType.name),
            subtitle: getTranslation(context, credential.issuer.name),
          )
        ],
      ),
    );
  }
}
