import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../screens/session/disclosure/models/disclosure_credential.dart';
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
  final CredentialInfo credentialInfo;
  final List<Attribute> attributes;
  final List<Attribute>? compareTo;
  final bool revoked;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final CardExpiryDate? expiryDate;
  final bool hideFooter;

  IrmaCredentialCard({
    Key? key,
    CredentialInfo? credentialInfo,
    this.attributes = const [],
    this.compareTo,
    this.revoked = false,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.expiryDate,
    this.hideFooter = false,
  })  : assert(
          credentialInfo != null || attributes.isNotEmpty,
          'Make sure you either provide attributes or credentialInfo',
        ),
        assert(
          attributes.isEmpty ||
              attributes.every((att) => att.credentialInfo.fullId == attributes.first.credentialInfo.fullId),
          'Make sure that all attributes belong to the same credential',
        ),
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
    this.hideFooter = false,
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
    this.expiryDate,
    this.hideFooter = false,
  })  : credentialInfo = credential.info,
        attributes = credential.attributeList,
        revoked = false;

  IrmaCredentialCard.fromDisclosureCredential(
    DisclosureCredential credential, {
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.padding,
    this.expiryDate,
    this.hideFooter = true,
  })  : credentialInfo = credential,
        attributes = credential.attributes,
        revoked = false;

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final isExpired = expiryDate?.expired ?? false;
    final isExpiringSoon = expiryDate?.expiresSoon ?? false;

    String footerTextKey;
    if (isExpired) {
      footerTextKey = 'credential.expired_on';
    } else if (isExpiringSoon) {
      footerTextKey = 'credential.expires_on';
    } else {
      footerTextKey = 'credential.valid_until';
    }

    final obtainable = (isExpired || isExpiringSoon || revoked) && credentialInfo.credentialType.issueUrl.isNotEmpty;

    return IrmaCard(
      style: isExpired || revoked ? IrmaCardStyle.disabled : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IrmaCredentialCardHeader(
            title: getTranslation(context, credentialInfo.credentialType.name),
            subtitle: getTranslation(context, credentialInfo.issuer.name),
            logo: credentialInfo.credentialType.logo,
            trailing: headerTrailing,
            isExpired: isExpired,
            isExpiringSoon: isExpiringSoon,
            isRevoked: revoked,
          ),
          // If there are attributes in this credential, then we show the attribute list
          if (attributes.any((att) => att.value is! NullValue)) ...[
            IrmaDivider(isDisabled: isExpired),
            IrmaCredentialCardAttributeList(
              attributes,
              compareTo: compareTo,
            ),
          ],
          if (!hideFooter) ...[
            IrmaDivider(
              isDisabled: isExpired || revoked,
            ),
            SizedBox(
              height: IrmaTheme.of(context).tinySpacing,
            ),
            IrmaCredentialCardFooter(
              credentialType: credentialInfo.credentialType,
              text: (expiryDate?.dateTime != null)
                  ? FlutterI18n.translate(
                      context,
                      footerTextKey,
                      translationParams: {
                        'date': printableDate(
                          expiryDate!.dateTime!,
                          lang,
                        ),
                      },
                    )
                  : null,
              isObtainable: obtainable,
            )
          ]
        ],
      ),
    );
  }
}
