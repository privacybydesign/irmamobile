import 'package:flutter/material.dart';

import '../../../../util/language.dart';
import '../../../../widgets/credential_card/card_credential_header.dart';
import '../../../../widgets/irma_card.dart';
import '../../models/template_disclosure_credential.dart';

class IrmaCredentialTemplateCard extends StatelessWidget {
  final TemplateDisclosureCredential credential;

  const IrmaCredentialTemplateCard(this.credential);

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      onTap: () {},
      dottedBorder: true,
      child: Column(
        children: [
          CardCredentialHeader(
            credentialName: getTranslation(context, credential.credentialType.name),
            issuerName: getTranslation(context, credential.issuer.name),
            type: CredentialHeaderType.template,
          )
        ],
      ),
    );
  }
}
