import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute.dart';
import '../../models/attribute_value.dart';
import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../models/translated_value.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../credential_card/models/card_expiry_date.dart';
import '../greyed_out.dart';
import '../information_box.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import '../yivi_themed_button.dart';
import 'yivi_credential_card_attribute_list.dart';
import 'yivi_credential_card_footer.dart';
import 'yivi_credential_card_header.dart';

class YiviCredentialCard extends StatelessWidget {
  final bool compact;
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

  /// when the instance count becomes lower than this,
  /// the re-obtain button shows and the instance count becomes the warning color
  static const int lowInstanceCountThreshold = 5;

  const YiviCredentialCard({
    super.key,
    required this.type,
    required this.issuer,
    required this.attributes,
    required this.valid,
    required this.expired,
    required this.revoked,
    required this.hashByFormat,
    required this.compact,
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

  static YiviCredentialCard fromCredentialLog(IrmaConfiguration irmaConfiguration, CredentialLog credential,
      {required bool compact}) {
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
      compact: compact,
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
    required this.compact,
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
    required this.compact,
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

    return IrmaCard(
      style: _isExpiredInAnyWay() ? IrmaCardStyle.danger : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GreyedOut(
            filterActive: disabled,
            child: YiviCredentialCardHeader(
              compact: compact,
              credentialName: getTranslation(context, type.name),
              issuerName: getTranslation(context, issuer.name),
              logo: type.logo,
              trailing: headerTrailing,
              isExpired: _isExpiredInAnyWay(),
              isRevoked: revoked,
              isExpiringSoon: _isExpiringSoonInAnyWay(),
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
                  color: _isExpiredInAnyWay() ? theme.danger : null,
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                ),
                YiviCredentialCardFooter(
                  credentialType: type,
                  issuer: issuer,
                  revoked: revoked,
                  instanceBasedExpireState: _getInstanceCountBasedExpireState(),
                  timeBasedExpireState: _getTimeBasedExpireState(),
                  expiryDate: expiryDate,
                  isTemplate: isTemplate,
                  instanceCount: instanceCount,
                ),
              ],
            ),
          _buildReobtainOption(context, theme),
        ],
      ),
    );
  }

  ExpireState _getTimeBasedExpireState() {
    if (expired) {
      return ExpireState.expired;
    }
    if (expiryDate?.expiresSoon ?? false) {
      return ExpireState.almostExpired;
    }
    return ExpireState.notExpired;
  }

  ExpireState _getInstanceCountBasedExpireState() {
    // idemix only, so doesn't expire
    if (instanceCount == null) {
      return ExpireState.notExpired;
    }
    if (instanceCount! <= 0) {
      return ExpireState.expired;
    }
    if (instanceCount! <= lowInstanceCountThreshold) {
      return ExpireState.almostExpired;
    }
    return ExpireState.notExpired;
  }

  bool _isExpiringSoonInAnyWay() {
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased != ExpireState.notExpired || instanceBased != ExpireState.notExpired;
  }

  bool _isExpiredInAnyWay() {
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased == ExpireState.expired || instanceBased == ExpireState.expired;
  }

  Widget _buildReobtainOption(BuildContext context, IrmaThemeData theme) {
    if (type.obtainable) {
      if (_isExpiringSoonInAnyWay()) {
        return Padding(
          padding: EdgeInsets.only(top: theme.defaultSpacing),
          child: YiviThemedButton(
            label: 'credential.options.reobtain',
            style: YiviButtonStyle.filled,
            onPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              type.fullId,
            ),
          ),
        );
      }
    } else if (!valid || isTemplate) {
      return InformationBox(
        message: FlutterI18n.translate(
          context,
          'credential.not_obtainable',
          translationParams: {
            'issuerName': issuer.name.translate(FlutterI18n.currentLocale(context)!.languageCode),
          },
        ),
      );
    }
    return Container();
  }
}
