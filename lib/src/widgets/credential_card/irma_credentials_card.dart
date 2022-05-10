import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../screens/session/models/disclosure_credential.dart';
import '../../screens/session/models/template_disclosure_credential.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import '../translated_text.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialsCard extends StatelessWidget {
  final Map<CredentialInfo, List<Attribute>> attributesByCredential;
  final List<DisclosureCredential>? compareToCredentials;
  final bool revoked;
  final CardExpiryDate? expiryDate;
  final Function()? onTap;
  final IrmaCardStyle style;

  const IrmaCredentialsCard({
    required this.attributesByCredential,
    this.compareToCredentials,
    this.revoked = false,
    this.expiryDate,
    this.onTap,
    this.style = IrmaCardStyle.normal,
  });

  factory IrmaCredentialsCard.fromAttributes(List<Attribute> attributes) {
    return IrmaCredentialsCard(
      attributesByCredential: groupBy(attributes, (Attribute attr) => attr.credentialInfo.fullId)
          .map((_, attrs) => MapEntry(attrs.first.credentialInfo, attrs)),
    );
  }

  IrmaCredentialsCard.fromCredentialInfo({
    Key? key,
    required CredentialInfo credentialInfo,
    List<Attribute> attributes = const [],
    TemplateDisclosureCredential? compareTo,
    this.onTap,
    this.expiryDate,
    this.style = IrmaCardStyle.normal,
    this.revoked = false,
  })  : attributesByCredential = {credentialInfo: attributes},
        compareToCredentials = compareTo != null ? [compareTo] : [],
        super(key: key);

  IrmaCredentialsCard.fromCredential({
    Key? key,
    required Credential credential,
    this.onTap,
  })  : attributesByCredential = {credential.info: credential.attributeList},
        revoked = credential.revoked,
        compareToCredentials = null,
        expiryDate = CardExpiryDate(credential.expires),
        style = IrmaCardStyle.normal,
        super(key: key);

  IrmaCredentialsCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : attributesByCredential = {credential.info: credential.attributeList},
        style = IrmaCardStyle.normal,
        revoked = false,
        expiryDate = null,
        compareToCredentials = null,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      style: style,
      onTap: onTap,
      child: attributesByCredential.keys.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: attributesByCredential.keys.expandIndexed(
                (i, credInfo) {
                  final translatedCredentialName = getTranslation(context, credInfo.credentialType.name);
                  final translatedIssuerName = getTranslation(context, credInfo.credentialType.name);
                  return [
                    IrmaCredentialCardHeader(
                      title: translatedCredentialName,
                      subtitle: translatedIssuerName,
                      logo: credInfo.credentialType.logo,
                      style: style,
                    ),
                    //If there are no attributes for this credential hide the attribute list.
                    if (attributesByCredential[credInfo]!.where((att) => att.value is! NullValue).isNotEmpty) ...[
                      IrmaDivider(style: style),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
                        child: IrmaCredentialCardAttributeList(
                          attributesByCredential[credInfo]!,
                          compareToAttributes:
                              compareToCredentials?[i] != null ? compareToCredentials![i].attributes : null,
                        ),
                      ),
                    ],
                    //If this is not the last item add a divider
                    if (i != attributesByCredential.keys.length - 1) IrmaDivider(style: style)
                  ];
                },
              ).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TranslatedText(
                  "credential.no_data",
                  style: theme.themeData.textTheme.bodyText1,
                ),
              ],
            ),
    );
  }
}
