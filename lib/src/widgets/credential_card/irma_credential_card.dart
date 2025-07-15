import 'package:flutter/material.dart';

import '../../models/attribute.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../greyed_out.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_footer.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialCard extends StatelessWidget {
  final CredentialView credentialView;
  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final CardExpiryDate? expiryDate;
  final bool hideFooter;
  final bool hideAttributes;
  final bool disabled;

  const IrmaCredentialCard({
    super.key,
    required this.credentialView,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.expiryDate,
    this.hideFooter = false,
    this.hideAttributes = false,
    this.disabled = false,
  });

  IrmaCredentialCard.fromCredential(
    Credential credential, {
    super.key,
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.padding,
    this.hideFooter = false,
    this.hideAttributes = false,
    this.disabled = false,
  }) : credentialView = credential,
       expiryDate = CardExpiryDate(credential.expires);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final isExpiringSoon = expiryDate?.expiresSoon ?? false;

    return IrmaCard(
      style: credentialView.valid ? style : IrmaCardStyle.danger,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only the header should be greyed out when the card is disabled.
          GreyedOut(
            filterActive: disabled,
            child: IrmaCredentialCardHeader(
              credentialName: getTranslation(context, credentialView.credentialType.name),
              issuerName: getTranslation(context, credentialView.issuer.name),
              logo: credentialView.credentialType.logo,
              trailing: headerTrailing,
              isExpired: credentialView.expired,
              isRevoked: credentialView.revoked,
              isExpiringSoon: isExpiringSoon,
            ),
          ),
          // If there are attributes in this credential, then we show the attribute list
          if (credentialView.attributesWithValue.isNotEmpty && !hideAttributes) ...[
            IrmaDivider(color: credentialView.valid ? null : theme.danger),
            IrmaCredentialCardAttributeList(credentialView.attributes, compareTo: compareTo),
          ],
          if (!hideFooter)
            IrmaCredentialCardFooter(
              credentialView: credentialView,
              expiryDate: expiryDate,
              padding: EdgeInsets.only(top: theme.smallSpacing),
            ),
        ],
      ),
    );
  }
}
