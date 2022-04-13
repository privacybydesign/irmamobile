import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_card.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialsCard extends StatelessWidget {
  final Map<CredentialInfo, List<Attribute>> attributesByCredential;
  final bool revoked;
  final CardExpiryDate? expiryDate;
  final bool selected;
  final Function()? onTap;

  const IrmaCredentialsCard({
    required this.attributesByCredential,
    this.revoked = false,
    this.expiryDate,
    this.onTap,
    this.selected = false,
  });

  factory IrmaCredentialsCard.fromAttributes(List<Attribute> attributes) {
    return IrmaCredentialsCard(
      attributesByCredential: groupBy(attributes, (Attribute attr) => attr.credentialInfo.fullId)
          .map((_, attrs) => MapEntry(attrs.first.credentialInfo, attrs)),
    );
  }

  IrmaCredentialsCard.fromCredential({Key? key, required Credential credential, this.onTap, this.selected = false})
      : attributesByCredential = {credential.info: credential.attributeList},
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  IrmaCredentialsCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : attributesByCredential = {credential.info: credential.attributeList},
        revoked = false,
        expiryDate = null,
        onTap = null,
        selected = false;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      style: selected ? IrmaCardStyle.selected : IrmaCardStyle.normal,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: attributesByCredential.keys
            .expandIndexed(
              (i, credInfo) => [
                IrmaCredentialCardHeader(
                  credentialName: getTranslation(context, credInfo.credentialType.name),
                  issuerName: getTranslation(context, credInfo.issuer.name),
                  logo: credInfo.credentialType.logo,
                ),
                //If there are no attributes for this credential hide the attirubte list.
                if (attributesByCredential[credInfo]!.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
                      child: IrmaCredentialCardAttributeList(attributesByCredential[credInfo]!)),
                ],
                //If this is not the last item add a divider
                if (i != attributesByCredential.keys.length - 1)
                  Divider(
                    color: selected == true ? theme.themeData.colorScheme.primary : Colors.grey.shade500,
                    thickness: 0.5,
                  ),
              ],
            )
            .toList(),
      ),
    );
  }
}
