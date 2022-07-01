import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_footer.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialCard extends StatelessWidget {
  final CredentialInfo credentialInfo;
  final List<Attribute> attributes;
  final List<Attribute>? compareTo;
  final bool revoked;
  final CardExpiryDate? expiryDate;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;

  IrmaCredentialCard({
    Key? key,
    CredentialInfo? credentialInfo,
    this.attributes = const [],
    this.compareTo,
    this.revoked = false,
    this.expiryDate,
    this.onTap,
    this.headerTrailing,
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
    this.padding,
  })  : credentialInfo = credential.info,
        attributes = credential.attributeList,
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  IrmaCredentialCard.fromRemovedCredential(
    RemovedCredential credential, {
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.padding,
  })  : credentialInfo = credential.info,
        attributes = credential.attributeList,
        revoked = false,
        expiryDate = null;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      margin: EdgeInsets.symmetric(
        vertical: theme.smallSpacing,
        horizontal: theme.defaultSpacing,
      ),
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
            Padding(
              //padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
              padding: EdgeInsets.zero,
              child: IrmaCredentialCardAttributeList(
                attributes,
                compareTo: compareTo,
              ),
            ),
          ],
          if (expiryDate != null) ...[
            const IrmaDivider(),
            IrmaCredentialCardFooter(
              expiryDate: expiryDate!,
            ),
          ]
        ],
      ),
    );
  }
}
