import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../util/language.dart';
import '../../../../widgets/credential_card/irma_credential_card_attribute_list.dart';
import '../../../../widgets/credential_card/irma_credential_card_header.dart';
import '../../../../widgets/dotted_divider.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../models/disclosure_credential.dart';
import '../../models/template_disclosure_credential.dart';

class IrmaDisclosureCredentialCard extends StatelessWidget {
  final DisclosureCredential credential;
  final TemplateDisclosureCredential? compareTo;
  final IrmaCardStyle style;
  final Function()? onTap;

  const IrmaDisclosureCredentialCard(
    this.credential, {
    this.style = IrmaCardStyle.normal,
    this.compareTo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      onTap: onTap != null
          ? () => onTap
          : style == IrmaCardStyle.template
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
                child: IrmaCredentialCardAttributeList(
                  credential.attributes,
                  compareTo: style == IrmaCardStyle.template || style == IrmaCardStyle.success
                      //If is template or success compare to self
                      ? credential.attributes
                      //If compare is not null compare to the template
                      : compareTo != null
                          ? compareTo!.attributes
                          : null,
                ))
          ]
        ],
      ),
    );
  }
}
