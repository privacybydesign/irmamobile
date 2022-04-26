import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../util/language.dart';
import '../../../../widgets/credential_card/irma_credential_card_attribute_list.dart';
import '../../../../widgets/credential_card/irma_credential_card_header.dart';
import '../../../../widgets/dotted_divider.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../models/disclosure_credential.dart';

class IrmaDisclosureCredentialCard extends StatelessWidget {
  final DisclosureCredential credential;
  final IrmaCardStyle style;

  const IrmaDisclosureCredentialCard(this.credential, {this.style = IrmaCardStyle.normal});

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      onTap: style == IrmaCardStyle.template
          ? () => IrmaRepositoryProvider.of(context).openIssueURL(context, credential.credentialType.fullId)
          : null,
      style: style == IrmaCardStyle.template ? IrmaCardStyle.template : IrmaCardStyle.normal,
      child: Column(
        children: [
          IrmaCredentialCardHeader(
            style: style,
            title: getTranslation(context, credential.credentialType.name),
            subtitle: getTranslation(context, credential.issuer.name),
          ),
          if (credential.attributesWithValue.isNotEmpty) ...[
            if (style == IrmaCardStyle.template) const DottedDivider() else const Divider(),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).largeSpacing),
                child: IrmaCredentialCardAttributeList(credential.attributes))
          ]
        ],
      ),
    );
  }
}
