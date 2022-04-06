import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/card/card_attribute_list.dart';

import '../../models/attributes.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import 'card_credential_header.dart';

class AttributesCardItem extends StatelessWidget {
  final List<Attribute> attributesByCredential;

  const AttributesCardItem(this.attributesByCredential);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardCredentialHeader(
          title: getTranslation(context, attributesByCredential.first.credentialInfo.credentialType.name),
          subtitle: getTranslation(context, attributesByCredential.first.credentialInfo.issuer.name),
          logo: attributesByCredential.first.credentialInfo.credentialType.logo,
        ),
        const Divider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
          child: CardAttributeList(attributesByCredential),
        )
      ],
    );
  }
}
