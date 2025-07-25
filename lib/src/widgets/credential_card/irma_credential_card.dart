import 'package:flutter/material.dart';

import '../../models/attribute.dart';
import '../../models/attribute_value.dart';
import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../models/translated_value.dart';
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
  final List<String> credentialFormats;

  const IrmaCredentialCard({
    super.key,
    required this.credentialView,
    required this.credentialFormats,
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

  static IrmaCredentialCard fromCredentialLog(IrmaConfiguration irmaConfiguration, CredentialLog credential) {
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

    return IrmaCredentialCard(
      credentialFormats: [],
      credentialView: credentialView,
      hideFooter: true,
    );
  }

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
  })  : credentialView = credential,
        credentialFormats = credential.credentialFormats,
        expiryDate = CardExpiryDate(credential.expires);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final isExpiringSoon = expiryDate?.expiresSoon ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IrmaCard(
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
              IrmaCredentialCardAttributeList(
                credentialView.attributes,
                compareTo: compareTo,
              ),
            ],
            if (!hideFooter)
              IrmaCredentialCardFooter(
                credentialView: credentialView,
                expiryDate: expiryDate,
                padding: EdgeInsets.only(top: theme.smallSpacing),
              ),
            SizedBox(height: theme.smallSpacing),
            Row(
              spacing: theme.smallSpacing,
              children: [
                for (final credentialFormat in credentialFormats) CredentialFormatTag(format: credentialFormat),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CredentialFormatTag extends StatelessWidget {
  const CredentialFormatTag({super.key, required this.format});

  final String format;

  @override
  Widget build(BuildContext context) {
    final text = format == 'idemix' ? 'Yivi' : 'Eudi';
    final color = format == 'idemix' ? Colors.red.shade800 : Colors.blue.shade800;
    final textStyle = IrmaTheme.of(context).textTheme.bodySmall;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
        child: Text(
          text,
          style: textStyle!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
