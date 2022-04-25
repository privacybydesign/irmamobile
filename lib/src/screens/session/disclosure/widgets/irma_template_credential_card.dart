import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../util/language.dart';
import '../../../../widgets/credential_card/irma_credential_card_attribute_list.dart';
import '../../../../widgets/credential_card/irma_credential_card_header.dart';
import '../../../../widgets/dotted_divider.dart';
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
      style: credential.obtained ? IrmaCardStyle.normal : IrmaCardStyle.template,
      child: Column(
        children: [
          IrmaCredentialCardHeader(
            type: credential.obtained ? CredentialHeaderType.success : CredentialHeaderType.template,
            title: getTranslation(context, credential.credentialType.name),
            subtitle: getTranslation(context, credential.issuer.name),
          ),
          if (credential.attributesWithValue.isNotEmpty) ...[
            const DottedDivider(),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).largeSpacing),
                child: IrmaCredentialCardAttributeList(credential.attributes))
          ]
        ],
      ),
    );
  }
}
