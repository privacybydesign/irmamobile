import 'package:flutter/material.dart';

import '../../models/attribute.dart';
import '../../models/attribute_value.dart';
import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../models/translated_value.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../credential_card/models/card_expiry_date.dart';
import '../greyed_out.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import 'yivi_credential_card_attribute_list.dart';
import 'yivi_credential_card_footer.dart';
import 'yivi_credential_card_header.dart';

class YiviCredentialCard extends StatelessWidget {
  final List<Attribute> attributes;
  final bool valid;
  final CredentialType type;
  final Issuer issuer;
  final bool expired;
  final bool revoked;
  final bool isTemplate;

  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final CardExpiryDate? expiryDate;
  final bool hideFooter;
  final bool hideAttributes;
  final bool disabled;
  final Map<CredentialFormat, String> hashByFormat;
  final int? instanceCount;

  const YiviCredentialCard({
    super.key,
    required this.type,
    required this.issuer,
    required this.attributes,
    required this.valid,
    required this.expired,
    required this.revoked,
    required this.hashByFormat,
    this.instanceCount,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.expiryDate,
    this.hideFooter = false,
    this.hideAttributes = false,
    this.disabled = false,
    this.isTemplate = false,
  });

  static YiviCredentialCard fromCredentialLog(IrmaConfiguration irmaConfiguration, CredentialLog credential) {
    final attributes = credential.attributes.entries.map((entry) {
      final attributeId = '${credential.credentialType}.${entry.key}';
      final attributeType = irmaConfiguration.attributeTypes[attributeId];
      final attributeValue = AttributeValue.fromRaw(
        attributeType!,
        TranslatedValue({
          '': entry.value,
          'en': entry.value,
          'nl': entry.value,
        }),
      );
      return Attribute(attributeType: attributeType, value: attributeValue);
    }).toList();

    final credentialView = CredentialView.fromAttributes(
      irmaConfiguration: irmaConfiguration,
      attributes: attributes,
    );

    return YiviCredentialCard(
      valid: credentialView.valid,
      type: credentialView.credentialType,
      issuer: credentialView.issuer,
      expired: credentialView.expired,
      revoked: credentialView.revoked,
      hashByFormat: Map.fromEntries(credential.formats.map((f) => MapEntry(f, ''))),
      attributes: credentialView.attributes,
      hideFooter: true,
    );
  }

  YiviCredentialCard.fromMultiFormatCredential(
    MultiFormatCredential credential, {
    super.key,
    this.compareTo,
    this.onTap,
    this.style = IrmaCardStyle.normal,
    this.headerTrailing,
    this.padding,
    this.hideFooter = false,
    this.hideAttributes = false,
    this.disabled = false,
    this.isTemplate = false,
  })  : attributes = credential.attributes,
        valid = credential.valid,
        type = credential.credentialType,
        expired = credential.expired,
        revoked = credential.revoked,
        issuer = credential.issuer,
        hashByFormat = credential.hashByFormat,
        instanceCount = credential.instanceCount,
        expiryDate = CardExpiryDate(credential.expires);

  YiviCredentialCard.fromCredential(
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
    this.isTemplate = false,
  })  : attributes = credential.attributes,
        valid = credential.valid,
        type = credential.credentialType,
        expired = credential.expired,
        revoked = credential.revoked,
        issuer = credential.issuer,
        hashByFormat = {credential.format: credential.hash},
        expiryDate = CardExpiryDate(credential.expires),
        instanceCount = credential.instanceCount;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final isExpiringSoon = expiryDate?.expiresSoon ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IrmaCard(
        style: valid ? style : IrmaCardStyle.danger,
        onTap: onTap,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GreyedOut(
              filterActive: disabled,
              child: YiviCredentialCardHeader(
                credentialName: getTranslation(context, type.name),
                issuerName: getTranslation(context, issuer.name),
                logo: type.logo,
                trailing: headerTrailing,
                isExpired: expired,
                isRevoked: revoked,
                isExpiringSoon: isExpiringSoon,
              ),
            ),
            // If there are attributes in this credential, then we show the attribute list
            if (attributes.any((a) => a.value is! NullValue) && !hideAttributes) ...[
              IrmaDivider(
                color: valid ? null : theme.danger,
                padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
              ),
              YiviCredentialCardAttributeList(
                attributes,
                compareTo: compareTo,
              ),
            ],
            if (!hideFooter)
              Column(
                children: [
                  IrmaDivider(
                    color: valid ? null : theme.danger,
                    padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                  ),
                  YiviCredentialCardFooter(
                    credentialType: type,
                    issuer: issuer,
                    revoked: revoked,
                    expired: expired,
                    valid: valid,
                    expiryDate: expiryDate,
                    isTemplate: isTemplate,
                    instanceCount: instanceCount,
                    // padding: EdgeInsets.only(top: theme.smallSpacing),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
