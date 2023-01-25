import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/date_formatter.dart';
import '../../util/language.dart';
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

  const IrmaCredentialCard({
    Key? key,
    required this.credentialView,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.expiryDate,
    this.hideFooter = false,
    this.hideAttributes = false,
  }) : super(key: key);

  IrmaCredentialCard.fromCredential(
    Credential credential, {
    Key? key,
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.padding,
    this.hideFooter = false,
    this.hideAttributes = false,
  })  : credentialView = credential,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

    final isInvalid = credentialView.expired || credentialView.revoked;
    final isExpiringSoon = expiryDate?.expiresSoon ?? false;

    return IrmaCard(
      style: isInvalid ? IrmaCardStyle.danger : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IrmaCredentialCardHeader(
            credentialName: getTranslation(context, credentialView.credentialType.name),
            issuerName: getTranslation(context, credentialView.issuer.name),
            logo: credentialView.credentialType.logo,
            trailing: headerTrailing,
            isExpired: credentialView.expired,
            isRevoked: credentialView.revoked,
            isExpiringSoon: isExpiringSoon,
          ),
          // If there are attributes in this credential, then we show the attribute list
          if (credentialView.attributesWithValue.isNotEmpty && !hideAttributes) ...[
            IrmaDivider(color: isInvalid ? theme.danger : null),
            IrmaCredentialCardAttributeList(
              credentialView.attributes,
              compareTo: compareTo,
            ),
          ],
          if (!hideFooter) ...[
            SizedBox(
              height: IrmaTheme.of(context).smallSpacing,
            ),
            IrmaCredentialCardFooter(
              credentialType: credentialView.credentialType,
              text: credentialView.revoked || expiryDate == null || expiryDate!.dateTime == null
                  ? null
                  : FlutterI18n.translate(
                      context,
                      credentialView.expired
                          ? 'credential.expired_on'
                          : isExpiringSoon
                              ? 'credential.expires_on'
                              : 'credential.valid_until',
                      translationParams: {
                        'date': printableDate(
                          expiryDate!.dateTime!,
                          lang,
                        ),
                      },
                    ),
              isObtainable: (isInvalid || isExpiringSoon) && credentialView.credentialType.issueUrl.isNotEmpty,
            )
          ]
        ],
      ),
    );
  }
}
