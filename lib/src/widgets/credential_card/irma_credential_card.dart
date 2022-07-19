import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_credential.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../util/language.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import '../translated_text.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';

class IrmaCredentialCard extends StatelessWidget {
  final CredentialInfo credentialInfo;
  final List<Attribute> attributes;
  final List<Attribute>? compareTo;
  final bool revoked;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final TranslatedText? trailingText;
  final EdgeInsetsGeometry? padding;

  IrmaCredentialCard({
    Key? key,
    CredentialInfo? credentialInfo,
    this.attributes = const [],
    this.compareTo,
    this.revoked = false,
    this.onTap,
    this.headerTrailing,
    this.trailingText,
    this.style = IrmaCardStyle.normal,
    this.padding,
  })  : assert(
          credentialInfo != null || attributes.isNotEmpty,
          'Make sure you either provide attributes or credentialInfo',
        ),
        assert(
            attributes.isEmpty ||
                attributes.every((att) => att.credentialInfo.fullId == attributes.first.credentialInfo.fullId),
            'Make sure that all attributes belong to the same credential'),
        credentialInfo = credentialInfo ?? attributes.first.credentialInfo,
        super(key: key);

  IrmaCredentialCard.fromCredential(
    Credential credential, {
    Key? key,
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.trailingText,
    this.padding,
  })  : credentialInfo = credential.info,
        attributes = credential.attributeList,
        revoked = credential.revoked,
        super(key: key);

  IrmaCredentialCard.fromRemovedCredential(
    RemovedCredential credential, {
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.trailingText,
    this.padding,
  })  : credentialInfo = credential.info,
        attributes = credential.attributeList,
        revoked = false;

  IrmaCredentialCard.fromDisclosureCredential(
    DisclosureCredential credential, {
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.trailingText,
    this.padding,
  })  : credentialInfo = credential,
        attributes = credential.attributes,
        revoked = false;

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      style: style,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IrmaCredentialCardHeader(
            title: getTranslation(context, credentialInfo.credentialType.name),
            subtitle: getTranslation(context, credentialInfo.issuer.name),
            logo: credentialInfo.credentialType.logo,
            trailing: headerTrailing,
          ),
          // If there are attributes in this credential, then we show the attribute list
          if (attributes.any((att) => att.value is! NullValue)) ...[
            const IrmaDivider(),
            IrmaCredentialCardAttributeList(
              attributes,
              compareTo: compareTo,
            ),
          ],
          if (trailingText != null) ...[
            const IrmaDivider(),
            trailingText!,
          ]
        ],
      ),
    );
  }
}
